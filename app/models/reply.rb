# frozen_string_literal: true

require "digest/md5"
class Reply < ApplicationRecord
  include SoftDelete, MarkdownBody, Mentionable, MentionTopic, UserAvatarDelegate
  include Reply::Notify, Reply::Voteable

  belongs_to :user, counter_cache: true
  belongs_to :topic, touch: true
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :reply_to, class_name: "Reply", optional: true

  delegate :title, to: :topic, prefix: true, allow_nil: true
  delegate :login, to: :user, prefix: true, allow_nil: true

  scope :without_system, -> { where(action: nil) }
  scope :fields_for_list, -> { select(:topic_id, :id, :body, :user_id, :exposed_to_author_only, :updated_at, :created_at) }

  # 最佳回复
  scope :suggest,            -> { where('suggested_at IS NOT NULL').order(suggested_at: :desc) }
  scope :no_suggest,         -> { where('suggested_at IS NULL') }
  scope :without_suggest,    -> { where(suggested_at: nil) }

  validates :body, presence: true, unless: -> { system_event? }
  validates :body, uniqueness: { scope: %i[topic_id user_id], message: "不能重复提交。" }, unless: -> { system_event? }
  validate do
    ban_words = (Setting.ban_words_on_reply || "").split("\n").collect(&:strip)
    if body && body.strip.downcase.in?(ban_words)
      errors.add(:body, "请勿回复无意义的内容，如你想收藏或赞这篇帖子，请用帖子后面的功能。")
    end

    if topic&.closed?
      errors.add(:topic, "已关闭，不再接受回帖或修改回帖。") unless system_event?
    end

    if reply_to_id
      self.reply_to_id = nil if reply_to&.topic_id != self.topic_id
    end
  end

  after_commit :update_parent_topic, on: :create, unless: -> { system_event? }
  def update_parent_topic
    topic.update_last_reply(self) if topic.present?
  end

  # 删除的时候也要更新 Topic 的 updated_at 以便清理缓存
  after_destroy :update_parent_topic_updated_at
  def update_parent_topic_updated_at
    unless topic.blank?
      topic.update_deleted_last_reply(self)
      # FIXME: 本应该 belongs_to :topic, touch: true 来实现的，但貌似有个 Bug 哪里没起作用
      topic.touch
    end
  end

  after_commit :async_create_reply_notify, on: :create, unless: -> { system_event? }
  def async_create_reply_notify
    NotifyReplyJob.perform_later(id)
  end

  after_commit :check_vote_chars_for_like_topic, on: :create, unless: -> { system_event? }
  def check_vote_chars_for_like_topic
    return unless self.upvote?
    user.like(topic)
  end

  def self.notify_reply_created(reply_id)
    reply = Reply.find_by_id(reply_id)
    return if reply.blank?
    return if reply.system_event?
    topic = Topic.find_by_id(reply.topic_id)
    return if topic.blank?

    notification_receiver_ids = reply.notification_receiver_ids
    if topic.private_org
      notification_receiver_ids = reply.private_org_notification_receiver_ids
    end

    if reply.exposed_to_author_only?
      notification_receiver_ids = []
      if reply.user_id != topic.user_id
        notification_receiver_ids = [topic.user_id]
      end
    end

    Notification.bulk_insert(set_size: 100) do |worker|
      notification_receiver_ids.each do |uid|
        logger.debug "Post Notification to: #{uid}"
        note = reply.default_notification.merge(user_id: uid)
        worker.add(note)
      end
    end

    # Touch realtime_push_to_client
    notification_receiver_ids.each do |uid|
      n = Notification.where(user_id: uid).last
      n.realtime_push_to_client if n.present?
    end
    Reply.broadcast_to_client(reply)

    true
  end

  def default_notification
    @default_notification ||= {
      notify_type: "topic_reply",
      target_type: "Reply", target_id: self.id,
      second_target_type: "Topic", second_target_id: self.topic_id,
      actor_id: self.user_id
    }
  end

  def notification_receiver_ids
    return @notification_receiver_ids if defined? @notification_receiver_ids
    # 加入帖子关注着
    follower_ids = self.topic.try(:follow_by_user_ids) || []
    # 加入回帖人的关注者
    follower_ids += self.user.try(:follow_by_user_ids) || []
    # 加入发帖人
    follower_ids << self.topic.try(:user_id)
    # 去重复
    follower_ids.uniq!
    # 排除回帖人
    follower_ids.delete(self.user_id)
    # 排除同一个回复过程中已经提醒过的人
    follower_ids -= self.mentioned_user_ids
    @notification_receiver_ids = follower_ids
  end

  def private_org_notification_receiver_ids
    return @private_org_notification_receiver_ids if defined? @private_org_notification_receiver_ids
    if topic.private_org
      follower_ids = topic&.team.team_users.accepted.pluck(:user_id) || []
      # 排除回帖人
      follower_ids.delete(self.user_id)
      @private_org_notification_receiver_ids = follower_ids
    else
      @private_org_notification_receiver_ids = []
    end
  end

  # 是否热门
  def popular?
    likes_count >= 5
  end

  def destroy
    super
    Notification.where(notify_type: "topic_reply", target: self).delete_all
    delete_notification_mentions
  end

  # 是否是系统事件
  def system_event?
    action.present?
  end

  def self.create_system_event!(opts = {})
    opts[:body] ||= ""
    opts[:user] ||= User.current
    return false if opts[:action].blank?
    return false if opts[:user].blank?
    self.create!(opts)
  end

  def suggested?
    self.suggested_at != nil
  end

  def update_suggested_at(time)
    self.update_attribute(:suggested_at, time)
  end

end
