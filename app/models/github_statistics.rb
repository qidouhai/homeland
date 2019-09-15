class GitHubStatistics
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      # fixme: 全部都放到 ClassMethods 其实不大合理。后续需要想办法优化成不用放到 module 里面。

      # 获取 Github 的统计信息
      def github_statistics
        statistics = Homeland.file_store.read(github_statistics_cache_key)
        if statistics.nil?
          Rails.logger.warn("Github statistics is nil! Maybe GitHubStatisticsFetcherJob is not working!")
          # fixme: 下面这行代码正常应该加上，但因为加了后执行会有问题，所以先注释掉。
          # GitHubStatisticsFetcherJob.perform_later
          statistics = default_statistics
        end
        Rails.logger.debug("Got github statistics: #{statistics.to_json}")
        statistics
      end

      def github_repo_stats_api_url(owner, repo)
        # 接口文档: https://developer.github.com/v3/repos/statistics/#get-contributors-list-with-additions-deletions-and-commit-counts
        # /repos/:owner/:repo/stats/contributors
        "https://api.github.com/repos/#{owner}/#{repo}/stats/contributors?client_id=#{Setting.github_token}&client_secret=#{Setting.github_secret}"
      end


      def github_statistics_cache_key
        "github-repos-statistics:1"
      end

      def default_statistics
        # fixme: 现在通过 key 而非类属性的形式存储，view 层使用会非常麻烦，需要修改。
        statistics = {
            "repos" => [],
            "all" => {}
        }
        statistics
      end

      def fetch_github_statistics_by_repo_url(repo_urls)
        repos = []

        repo_urls.collect do |repo_url|
          repo_owner, repo_name = repo_url.match('https:\/\/github.com\/(?<repo_owner>\w.*)\/(?<repo_name>\w.*)').captures

          # 逐个获取原始数据
          url = github_repo_stats_api_url(repo_owner, repo_name)
          begin
            retries ||= 0
            json = Timeout.timeout(10) { open(url).read }
          rescue StandardError => e
            # 请求接口次数比较多，稳定性不好保障，所以加上重试提高稳定性
            retry if (retries += 1) < 5
            Rails.logger.error("GitHub Statistics fetch Error: #{e}")
            Homeland.file_store.write(GitHubStatistics.github_statistics_cache_key, default_statistics, expires_in: 1.minutes)
            return
          end

          github_contributors = JSON.parse(json)
          contributors = []

          github_contributors.collect do |github_contributor|
            # 做个适配，后续即使 github api 数据结构有变化，通过这个地方适配即可
            contributor = {
                "github_login" => github_contributor["author"]["login"],
                "total" => github_contributor["total"],
                "is_testerhome_user" => false
            }

            # 给 contributors 加上 is_testerhome_user 标签
            if User.find_by_github(contributor["github_login"])
              contributor["is_testerhome_user"] = true
            end

            contributors << contributor
          end


          # 按 commit 总次数，从多到少排序
          contributors.sort! { |a, b| b["total"] <=> a["total"] }

          repo = {
              "name" => "#{repo_owner}/#{repo_name}",
              "url" => repo_url,
              "contributors" => contributors
          }

          repos << repo
          Rails.logger.debug("Saved repo: #{repo_url}")
        end

        repos
      end

      def sum_contributors_by_repos(repos)
        sum_contributors = []

        repos.collect do |repo|
          repo["contributors"].collect do |repo_contributor|
            # 寻找是否已有同名的贡献者
            exist_sum_contributors = sum_contributors.select {|x| x["github_login"] == repo_contributor["github_login"] }
            if exist_sum_contributors.size > 0
              # 已存在，只需要累加 total
              exist_sum_contributors[0]["total"] += repo_contributor["total"]
            else
              # 不存在，需要新增元素
              sum_contributor = {
                  "github_login" => repo_contributor["github_login"],
                  "total" => repo_contributor["total"],
                  "is_testerhome_user" => repo_contributor["is_testerhome_user"]
              }

              sum_contributors << sum_contributor
            end
          end
        end

        # 按 commit 总次数，从多到少排序
        sum_contributors.sort! { |a, b| b["total"] <=> a["total"] }

        sum_contributors
      end

      def get_all_repo_urls
        Setting.github_stats_repos_list
      end


      def fetch_github_statistics
        repo_urls = get_all_repo_urls

        statistics = default_statistics

        # 放到 repos 中，一个 repo 一个元素
        statistics["repos"] = fetch_github_statistics_by_repo_url(repo_urls)
        logger.debug("All saved statistics after get all repos: #{statistics.to_json}")


        # 统计得出 all 的统计数据
        statistics["all"] = {
            "name" => "all",
            "url" => nil,
            "contributors" => sum_contributors_by_repos(statistics["repos"])
        }
        logger.debug("All saved statistics after sum all: #{statistics.to_json}")


        Homeland.file_store.write(github_statistics_cache_key, statistics, expires_in: 30.minutes)
        statistics
      end
    end


end