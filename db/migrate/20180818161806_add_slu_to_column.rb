class AddSluToColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :columns, :slug, :string, null: false
  end
end
