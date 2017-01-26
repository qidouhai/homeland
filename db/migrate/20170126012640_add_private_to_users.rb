class AddPrivateToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :private, :boolean, default: false, null: false
  end
end
