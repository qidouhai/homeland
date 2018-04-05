module Homeland::Jobs
  class JobsController < ::ApplicationController
    before_action :set_node

    def index
      @suggest_topics = Topic.where(node_id: @node.id).withoutDraft.suggest_all_parts.limit(4)
      suggest_topic_ids = @suggest_topics.map(&:id)
      @topics = Topic.where(node_id: @node.id).withoutDraft
      @topics = @topics.where.not(id: suggest_topic_ids) if suggest_topic_ids.count > 0
      @topics = @topics.last_actived.includes(:user).page(params[:page])
      @topics = @topics.where("title LIKE ?", "%[#{params[:location]}]%") if params[:location]
      @page_title = "#{t('menu.bugs')} - #{t('menu.topics')}"
      render '/topics/index'
    end

    def show
    end

    private

    def set_node
      @node = Node.find_builtin_node(19, '招聘')
    end
  end
end