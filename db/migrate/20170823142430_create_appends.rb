class CreateAppends < ActiveRecord::Migration[5.1]
  def change
    create_table :appends do |t|
      t.text :content
      t.timestamps
    end
  end
end
