class AddArticlePublicToTopics < ActiveRecord::Migration[5.2]
  def change
    add_column :topics, :article_public, :boolean, default: true , null: false
  end
end
