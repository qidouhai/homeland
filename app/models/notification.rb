# frozen_string_literal: true

# Auto generate with notifications gem.
class Notification < ActiveRecord::Base
  include Notifications::Model

  after_create :realtime_push_to_client
  after_update :realtime_push_to_client

  # 消息分组与 notifiy_type 的映射关系。 key 按照优先级来排序
  @@group_to_nofity_type = {
      "system" => { "types" => ["admin_sms", "node_changed"], "icon" => "fa-bullhorn" },
      "team" => { "types" =>  ["team_invite", "team_join", "reject_user_join"], "icon" => "fa-group" },
      "personal" => { "types" =>  ["append", "comment", "follow", "mention", "topic", "topic_reply"], "icon" => "fa-bell" }
  }

  def self.default_group
    @@group_to_nofity_type.keys[0]
  end

  def self.available_group?(group_name)
    @@group_to_nofity_type.has_key?(group_name)
  end

  def self.available_groups
    @@group_to_nofity_type.keys
  end

  def self.get_notify_types_by_group(group_name)
    @@group_to_nofity_type[group_name]["types"]
  end

  def self.get_icon_by_group(group_name)
    @@group_to_nofity_type[group_name]["icon"]
  end

  def realtime_push_to_client
    if user
      Notification.realtime_push_to_client(user)
      PushJob.perform_later(user_id, apns_note)
    end
  end

  def self.realtime_push_to_client(user)
    ActionCable.server.broadcast("notifications_count/#{user.id}", count: Notification.unread_count(user))
  end

  def self.unread_count_by_group(user, group)
    Notification.where(user: user, notify_type: Notification.get_notify_types_by_group(group)).unread.count
  end

  def apns_note
    @note ||= { alert: notify_title, badge: Notification.unread_count(user) }
  end

  def notify_title
    return "" if self.actor.blank?
    if notify_type == "topic"
      "#{self.actor.login} 创建了话题 《#{self.target.title}》"
    elsif notify_type == "topic_reply"
      "#{self.actor.login} 回复了话题 《#{self.second_target.title}》"
    elsif notify_type == "follow"
      "#{self.actor.login} 开始关注你了"
    elsif notify_type == "mention"
      "#{self.actor.login} 提及了你"
    elsif notify_type == "node_changed"
      "你的话题被移动了节点到 #{self.second_target.name}"
    else
      ""
    end
  end

  def self.notify_follow(user_id, follower_id)
    opts = {
      notify_type: "follow",
      user_id: user_id,
      actor_id: follower_id
    }
    return if Notification.where(opts).count > 0
    Notification.create opts
  end
end
