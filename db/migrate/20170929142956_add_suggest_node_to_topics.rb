class AddSuggestNodeToTopics < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :suggested_node, :integer, default: nil
  end
end
