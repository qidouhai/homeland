class AddCommentToTeamUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :team_users, :comment, :text
  end
end
