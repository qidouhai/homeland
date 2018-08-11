class Column < ApplicationRecord
  include SoftDelete, MarkdownBody, Searchable

  mount_uploader :cover, PhotoUploader
  validates :cover, :name, presence: true

  belongs_to :user, inverse_of: :topics, counter_cache: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :topics, dependent: :destroy
end
