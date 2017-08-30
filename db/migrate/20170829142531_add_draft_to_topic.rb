class AddDraftToTopic < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :draft, :boolean, default: false, null: false
  end
end
