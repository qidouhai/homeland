# frozen_string_literal: true

class Topic < ApplicationRecord
  include SoftDelete, MarkdownBody, Mentionable, MentionTopic, Closeable, Searchable, UserAvatarDelegate
  include Topic::Actions, Topic::AutoCorrect, Topic::Search, Topic::Notify, Topic::RateLimit

  # 临时存储检测用户是否读过的结果
  attr_accessor :read_state, :admin_editing

  # 修改了帖子的管理员
  belongs_to :modified_admin, class_name: 'User', optional: true

  belongs_to :user, inverse_of: :topics, counter_cache: true, optional: true
  belongs_to :team, counter_cache: true, optional: true
  belongs_to :node, counter_cache: true, optional: true
  belongs_to :last_reply_user, class_name: "User", optional: true
  belongs_to :last_reply, class_name: "Reply", optional: true
  has_many :replies, dependent: :destroy
  has_many :appends

  validates :user_id, :title, :body, :node_id, presence: true

  validate do

    if User.redis.SISMEMBER("blocked_users", user_id) == 1
      errors.add(:base, "由于你经常发布无意义的内容或者敏感词，屏蔽一天！")
    else
      ban_words = (Setting.ban_words_on_topic || "").split("\n").collect(&:strip)
      for ban_word in ban_words
        if body && body.strip.downcase.include?(ban_word) || title.strip.downcase.include?(ban_word)
          add_to_blocked_user
          errors.add(:base, "请勿发布无意义的内容或者敏感词，请勿挑战！")
        end
      end
    end
  end

  counter :hits, default: 0

  delegate :login, to: :user, prefix: true, allow_nil: true
  delegate :body, to: :last_reply, prefix: true, allow_nil: true

  # scopes
  scope :last_actived,       -> { order(last_active_mark: :desc) }
  scope :suggest,            -> { where('suggested_at IS NOT NULL and suggested_node is NULL').order(suggested_at: :desc) }
  scope :suggest_all_parts,  -> { where('suggested_at IS NOT NULL').order(suggested_at: :desc) }
  scope :no_suggest,         -> { where('suggested_at IS NULL and suggested_node is NULL') }
  scope :without_suggest,    -> { where(suggested_at: nil) }
  scope :high_likes,         -> { order(likes_count: :desc).order(id: :desc) }
  scope :with_replies_or_likes,       -> { where('replies_count >= 1 or likes_count >= 1') }
  scope :high_replies,       -> { order(replies_count: :desc).order(id: :desc) }
  scope :last_reply,         -> { where("last_reply_id IS NOT NULL").order(last_reply_id: :desc) }
  scope :no_reply,           -> { where(replies_count: 0) }
  scope :popular,            -> { where("likes_count > 15 or excellent >= 1") }
  scope :excellent,          -> { where("excellent >= 1") }
  scope :without_hide_nodes, -> { exclude_column_ids("node_id", Topic.topic_index_hide_node_ids) }

  scope :without_node_ids,   ->(ids) { exclude_column_ids("node_id", ids) }
  scope :without_users,      ->(ids) { exclude_column_ids("user_id", ids) }
  scope :exclude_column_ids, ->(column, ids) { ids.empty? ? all : where.not(column => ids) }
  scope :without_columns, ->(ids) { where.not("column_id" => ids).or(where(column_id: nil)) }

  scope :in_seven_days,         ->{ where('created_at >= ?', 1.week.ago) }
  scope :open, -> { where('closed_at IS NULL').order(created_at: :desc) }
  scope :without_nodes, lambda { |node_ids|
    ids = node_ids + Topic.topic_index_hide_node_ids
    ids.uniq!
    exclude_column_ids("node_id", ids)
  }
  scope :withoutDraft, -> { where(draft: false) }
  scope :withoutNotPublicArticles, -> { where(article_public: true) }

  before_save { self.node_name = node.try(:name) || "" }
  before_create { self.last_active_mark = Time.now.to_i }

  def self.fields_for_list
    columns = %w[body who_deleted]
    select(column_names - columns.map(&:to_s))
  end

  def full_body
    ([self.body] + self.replies.pluck(:body)).join('\n\n')
  end

  def self.topic_index_hide_node_ids
    Setting.node_ids_hide_in_topics_index.to_s.split(",").collect(&:to_i)
  end

  # 所有的回复编号
  def reply_ids
    Rails.cache.fetch([self, "reply_ids"]) do
      self.replies.order("id asc").pluck(:id)
    end
  end

  def update_last_reply(reply, force: false)
    # replied_at 用于最新回复的排序，如果帖着创建时间在一个月以前，就不再往前面顶了
    return false if reply.blank? && !force

    self.last_active_mark = Time.now.to_i if created_at > 3.month.ago
    self.replied_at = reply.try(:created_at)
    self.replies_count = replies.without_system.count
    self.last_reply_id = reply.try(:id)
    self.last_reply_user_id = reply.try(:user_id)
    self.last_reply_user_login = reply.try(:user_login)
    self.last_reply_user = reply&.user

    # Reindex Search document
    SearchIndexer.perform_later("update", "topic", self.id)
    save
  end

  def update_when_append(append, opts = {})
    return false if append.blank? && !opts[:force]
    update!(last_active_mark: Time.now.to_i)
    SearchIndexer.perform_later("update", "topic", self.id)
  end

  # 更新最后更新人，当最后个回帖删除的时候
  def update_deleted_last_reply(deleted_reply)
    return false if deleted_reply.blank?
    return false if last_reply_user_id != deleted_reply.user_id

    previous_reply = replies.without_system.where.not(id: deleted_reply.id).recent.first
    update_last_reply(previous_reply, force: true)
  end

  def floor_of_reply(reply)
    reply_index = reply_ids.index(reply.id)
    reply_index + 1
  end

  def self.total_pages
    return @total_pages if defined? @total_pages

    total_count = Rails.cache.fetch("topics/total_count", expires_in: 1.week) do
      self.unscoped.count
    end
    if total_count >= 1500
      @total_pages = 60
    end
    @total_pages
  end

  def topic_type
    (self[:type] || "Topic").underscore.to_sym
  end

  def isArticle?
    topic_type == :article
  end

  def add_to_blocked_user
    key = user_id.to_s + "-" +Time.now.strftime("%Y-%m-%d")
    hit_blacklist = User.redis.get(key)
    if not hit_blacklist
      User.redis.set(key, 1)
      User.redis.expire(key, 86400)
    else
      hit_blacklist_counter = hit_blacklist.to_i
      if hit_blacklist_counter <=5
        User.redis.incr(key)
      else
        User.redis.sadd("blocked_users", user_id)
        User.redis.expire("blocked_users", 86400)
      end
    end
  end
end
