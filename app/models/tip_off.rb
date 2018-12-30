class TipOff < ApplicationRecord
  include SoftDelete

  belongs_to :reporter, :class_name => 'User'
  belongs_to :follower, :class_name => 'User'

  enum type: { spam: 'spam', illegal: 'illegal', unfriendly: 'unfriendly', other: 'other' }
end
