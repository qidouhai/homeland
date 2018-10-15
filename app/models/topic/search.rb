# frozen_string_literal: true

class Topic
  module Search
    extend ActiveSupport::Concern

    included do
      mapping do
        indexes :title, type: :string, term_vector: :yes, analyzer: 'ik_smart'
        indexes :body,  type: :string, term_vector: :yes, analyzer: 'ik_smart'
      end
    end

    def as_indexed_json(_options = {})
      {
          title: self.title,
          body: self.full_body,
          node_name: self.node_name,
          updated_at: self.updated_at,
          excellent: self.excellent,
          draft: self.draft,
          private_org: self.private_org,
          type_order: self.type_order
      }
    end

    def type_order
      1
    end

    def private_org
      self&.team.private? if self.team
    end

    def indexed_changed?
      saved_change_to_title? || saved_change_to_body?
    end

    def related_topics(limit: 5)
      i = self.class.index_name
      t = self.class.document_type
      c = self.class

      if self.topic_type == :article
        i = "topics"
        t = "topic"
        c = Topic
      end
      opts = {
        query: {
          more_like_this: {
            fields: %i[title body],
            like: [
              {
                _index: i,
                _type: t,
                _id: id
              }
            ],
            min_term_freq: 2,
            min_doc_freq: 5
          }
        },
        size: limit
      }
      c.__elasticsearch__.search(opts).records.to_a
    end
  end
end
