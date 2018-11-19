# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::ApplicationController
    before_action :set_topic, only: [:show, :edit, :update, :destroy, :undestroy, :suggest, :unsuggest, :pop_suggest]

    def index
      @topics = Topic.unscoped
      if params[:q].present?
        qstr = "%#{params[:q].downcase}%"
        @topics = @topics.where("title LIKE ?", qstr)
      end
      if params[:login].present?
        u = User.find_by_login(params[:login])
        @topics = @topics.where("user_id = ?", u.try(:id))
      end
      if params[:draft].present?
        @topics = @topics.where("draft", true)
      end
      @topics = @topics.order(id: :desc)
      @topics = @topics.includes(:user).page(params[:page])
    end

    def show
    end

    def new
      @topic = Topic.new
    end

    def edit
    end

    def create
      @topic = Topic.new(params[:article].permit!)

      if @topic.save
        redirect_to(admin_topics_path, notice: "Topic was successfully created.")
      else
        render action: "new"
      end
    end

    def update
      if @topic.update(params[:article].permit!)
        redirect_to(admin_topics_path, notice: "Topic was successfully updated.")
      else
        render action: "edit"
      end
    end

    def delete_topics_by_ids
      topic_ids = params[:topic_ids]
      topic_ids.each do |tid|
        topic = Topic.find tid
        topic.update_attributes(modified_admin: current_user)
        topic.destroy_by(current_user)
      end
    end

    def destroy
      @topic.update_attributes(modified_admin: current_user)
      @topic.destroy_by(current_user)
      redirect_to(admin_topics_path)
    end

    def undestroy
      @topic.update_attribute(:deleted_at, nil)
      @topic.update_attributes(modified_admin: current_user)
      redirect_to(admin_topics_path)
    end

    def pop_suggest
      @topic
    end

    def suggest
      @topic.update_attribute(:suggested_at, Time.now)
      @topic.update_attribute(:suggested_node, params[:suggested_node]) unless params[:suggested_node].blank?
      @topic.update_attributes(modified_admin: current_user)
      redirect_to(@topic, notice: "Topic:#{params[:id]} suggested.")
    end

    def unsuggest
      @topic.update_attribute(:suggested_at, nil)
      @topic.update_attribute(:suggested_node, nil)
      @topic.update_attributes(modified_admin: current_user)
      redirect_to(@topic, notice: "Topic:#{params[:id]} unsuggested.")
    end

    private

      def set_topic
        @topic = Topic.unscoped.find(params[:id])
      end
  end
end
