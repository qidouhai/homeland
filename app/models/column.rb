class Column < ApplicationRecord
  include SoftDelete, MarkdownBody, Searchable

  mount_uploader :cover, PhotoUploader
  validates :cover, :name, :slug, presence: true
  validates :name, uniqueness: { scope: %i[user_id], message: "专栏名重复"  }
  validates :slug, uniqueness: { scope: %i[user_id], message: "专栏别名重复"  }

  SLUG_FORMAT              = 'A-Za-z0-9\-\_\.'
  ALLOW_SLUG_FORMAT_REGEXP = /\A[#{SLUG_FORMAT}]+\z/

  belongs_to :user, inverse_of: :topics, counter_cache: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :topics, dependent: :destroy

  validate do
    if self.new_record?
      if self.user && self.user.columns.length >= Setting.column_max_count.to_i
        errors.add(:base, "你已经有很多专栏啦！")
      end
    end
  end

  def self.find_by_slug(slug)
    return nil unless slug.match? ALLOW_SLUG_FORMAT_REGEXP
    fetch_by_uniq_keys(slug: slug) || where("lower(slug) = ?", slug.downcase).take
  end

  def to_param
    slug
  end
end
