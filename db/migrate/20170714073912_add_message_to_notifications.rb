class AddMessageToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :new_notifications, :message, :text
  end
end
