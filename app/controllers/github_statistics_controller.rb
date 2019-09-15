# frozen_string_literal: true

class GitHubStatisticsController < ApplicationController
  include GitHubStatistics::ClassMethods

  def index
    if github_statistics.nil? or github_statistics['all'].nil? or github_statistics['all']['contributors'].nil?
      @opensource_contributors = []
      @opensource_repos = []
    else
      @opensource_contributors = github_statistics['all']['contributors']
      @opensource_repos = github_statistics['repos']
    end
    Rails.logger.debug("Got opensource contributors: #{@opensource_contributors}")
  end

end
