class AddSocialContactToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :webchat, :string
    add_column :users, :webchat_public, :boolean
    add_column :users, :qq_public, :boolean
    add_column :users, :weibo, :string
    add_column :users, :weibo_public, :boolean
  end
end
