class AddReceiveNotificaitonToTeamUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :team_users, :is_receive_notifications, :boolean, default: true, null: false
  end
end
