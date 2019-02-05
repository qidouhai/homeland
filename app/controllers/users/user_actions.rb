# frozen_string_literal: true

module Users
  module UserActions
    extend ActiveSupport::Concern

    included do
      # TODO: 草稿、我的举报，应该只能本人可见，其它人无权限查看。
      before_action :authenticate_user!, only: [:block, :unblock, :blocked, :follow, :unfollow, :drafts, :@tipOffs]
      before_action :only_user!, only: [:topics, :replies, :favorites, :columns,
                                        :block, :unblock, :follow, :unfollow,
                                        :followers, :following, :calendar, :reward]
    end

    def topics
      @topics = @user.topics.withoutDraft.fields_for_list.recent
      @topics = @topics.page(params[:page])
    end

    def columns
      @columns = @user.columns
    end

    def replies
      @replies = @user.replies.without_system.fields_for_list.recent
      @replies = @replies.page(params[:page])
    end

    def favorites
      @topics = @user.favorites_topics_and_articles.withoutDraft.order("actions.id desc")
      @topics = @topics.page(params[:page])
    end

    def block
      current_user.block_user(@user.id)
      render json: { code: 0 }
    end

    def unblock
      current_user.unblock_user(@user.id)
      render json: { code: 0 }
    end

    def blocked
      if current_user.id != @user.id
        render_404
      end

      @block_users = @user.block_users.order("actions.id asc").page(params[:page])
    end

    def drafts
      @drafts = @user.my_drafts
    end

    def follow
      current_user.follow_user(@user)
      @user = User.find_by_id(@user.id)
      render json: { code: 0, data: { followers_count: @user.followers_count } }
    end

    def unfollow
      current_user.unfollow_user(@user)
      @user = User.find_by_id(@user.id)
      render json: { code: 0, data: { followers_count: @user.followers_count } }
    end

    def followers
      @users = @user.follow_by_users.normal.order('actions.id asc')
      @users = @users.page(params[:page]).per(60)
    end

    def following
      @users = @user.follow_users.normal.order('actions.id asc')
      @users = @users.page(params[:page]).per(60)
      render template: "/users/followers"
    end

    def tip_offs
      @tipOffs = TipOff.by_reporter(@user.id).order('create_time asc').page(params[:page])
    end

    def calendar
      data = @user.calendar_data
      render json: data if stale?(data)
    end

    def reward
    end

    private

      def only_user!
        render_404 if @user_type != :user
      end

    def user_show
      # 排除掉几个非技术的节点
      without_node_ids = [21, 22, 23, 31, 49, 51, 57, 25]
      @topics = @user.topics.withoutDraft.fields_for_list.without_node_ids(without_node_ids).high_likes.limit(20)
      @replies = @user.replies.without_system.fields_for_list.recent.includes(:topic).limit(10)
    end
  end
end
