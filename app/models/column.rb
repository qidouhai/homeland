class Column < ApplicationRecord
  include SoftDelete, MarkdownBody, Searchable

  mount_uploader :cover, PhotoUploader
  validates :cover, :name, :slug, presence: true
  validates :name, uniqueness: { scope: %i[user_id], message: "专栏名重复"  }
  validates :slug, uniqueness: { scope: %i[user_id], message: "专栏名重复"  }

  SLUG_FORMAT              = 'A-Za-z0-9\-\_\.'
  ALLOW_SLUG_FORMAT_REGEXP = /\A[#{SLUG_FORMAT}]+\z/

  belongs_to :user, inverse_of: :topics, counter_cache: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :topics, dependent: :destroy

  def self.find_by_slug(slug)
    return nil unless slug.match? ALLOW_SLUG_FORMAT_REGEXP
    fetch_by_uniq_keys(slug: slug) || where("lower(slug) = ?", slug.downcase).take
  end

  def to_param
    slug
  end
end
