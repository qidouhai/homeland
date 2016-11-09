class AddSocialContactToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :wechat, :string
    add_column :users, :wechat_public, :boolean
    add_column :users, :qq_public, :boolean
    add_column :users, :weibo, :string
    add_column :users, :weibo_public, :boolean
  end
end
