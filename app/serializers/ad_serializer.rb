class AdSerializer < BaseSerializer
  attributes :id, :cover, :created_at, :topic_author, :topic_id, :topic_title, :updated_at

  def cover
    object.cover.url
  end
end