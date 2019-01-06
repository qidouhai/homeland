class CreateTipOffs < ActiveRecord::Migration[5.2]
  def change
    create_table :tip_offs do |t|
      t.integer :reporter_id
      t.string :reporter_email
      t.string :tip_off_type
      t.string :body
      t.datetime :create_time
      t.string :content_url
      t.integer :follower_id
      t.datetime :follow_time
      t.datetime :deleted_at
    end
  end
end
