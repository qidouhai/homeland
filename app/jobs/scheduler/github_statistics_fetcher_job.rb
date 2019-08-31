# frozen_string_literal: true

module Scheduler
  class GitHubStatisticsFetcherJob < ApplicationJob
    queue_as :http_request
    include GitHubStatistics::ClassMethods

    # update github statistics
    # fixme: 现有是为了能跑通，所以才采用了 include ClassMethods 的方式。正常不应该这么用。
    def perform
      fetch_github_statistics
    end

  end
end
