if ad
  json.cache! ["v1", ad] do
    json.(ad, :id, :topic_id, :topic_title, :topic_author, :created_at, :updated_at)
    json.cover ad.cover.url
  end
end