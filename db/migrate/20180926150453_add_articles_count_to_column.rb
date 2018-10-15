class AddArticlesCountToColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :columns, :articles_count, :integer, default: 0, null: false
  end
end
