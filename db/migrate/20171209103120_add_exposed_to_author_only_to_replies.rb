class AddExposedToAuthorOnlyToReplies < ActiveRecord::Migration[5.1]
  def change
    add_column :replies, :exposed_to_author_only, :boolean, default: false, null: false
  end
end
