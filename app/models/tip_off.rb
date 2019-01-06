class TipOff < ApplicationRecord
  include SoftDelete

  belongs_to :reporter, :class_name => 'User'
  belongs_to :follower, :class_name => 'User', optional: true

  validates :content_url, :reporter_email, :tip_off_type, :body, presence: true

end
