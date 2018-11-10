class AddFollowersCountToColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :columns, :followers_count, :integer, default: 0
  end
end
