class AddColumnToTopic < ActiveRecord::Migration[5.2]
  def change
    add_column :topics, :column_id, :integer
  end
end
