class Column < ApplicationRecord
  include SoftDelete, MarkdownBody, Searchable

  mount_uploader :cover, PhotoUploader
  validates :cover, :name, :slug, presence: true
  validates :name, uniqueness: { scope: %i[user_id], message: "专栏名重复"  }
  validates :slug, uniqueness: { scope: %i[user_id], message: "专栏名重复"  }

  belongs_to :user, inverse_of: :topics, counter_cache: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :topics, dependent: :destroy

  def to_param
    name
  end
end
