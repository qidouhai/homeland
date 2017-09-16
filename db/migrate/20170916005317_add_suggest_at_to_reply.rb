class AddSuggestAtToReply < ActiveRecord::Migration[5.1]
  def change
    add_column :replies, :suggested_at, :datetime, default: nil
  end
end
