class AddReferencesToAppends < ActiveRecord::Migration[5.1]
  def change
    add_reference :appends, :topic, foreign_key: true
  end
end
