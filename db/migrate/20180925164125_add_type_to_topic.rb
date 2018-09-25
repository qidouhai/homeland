class AddTypeToTopic < ActiveRecord::Migration[5.2]
  def change
    add_column :topics, :type, :string
  end
end
