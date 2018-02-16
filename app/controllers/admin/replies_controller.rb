module Admin
  class RepliesController < Admin::ApplicationController
    before_action :set_reply, only: %i[show edit update destroy]

    def index
      @replies = Reply.unscoped
      if params[:q].present?
        qstr = "%#{params[:q].downcase}%"
        @replies = @replies.where("body LIKE ?", qstr)
      end
      if params[:login].present?
        u = User.find_by_login(params[:login])
        @replies = @replies.where("user_id = ?", u.try(:id))
      end
      @replies = @replies.order(id: :desc).includes(:topic, :user)
      @replies = @replies.page(params[:page])
    end

    def show
      if @reply.topic.blank?
        redirect_to admin_replies_path, alert: "帖子已经不存在"
      end
    end

    def update
      @reply.update(reply_params)
      redirect_to admin_replies_path, alert: "修改完成"
    end

    def destroy
      @reply.destroy
    end

    def suggest
      @reply.update_suggested_at(Time.now)
      redirect_to(@reply, notice: "Reply:#{params[:id]} suggested.")
    end

    def unsuggest
      @reply.update_suggested_at(nil)
      redirect_to(@reply, notice: "Reply:#{params[:id]} unsuggested.")
    end

    private

    def set_reply
      @reply = Reply.unscoped.find(params[:id])
    end

    def reply_params
      params.require(:reply).permit(:body, :reply_to_id, :anonymous)
    end

  end
end
