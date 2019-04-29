module Searchable
  module PlaylistExtension

    def self.included(base)
      base.class_eval do
        index_name "playlists-#{Rails.env}"

        settings index: { number_of_shards: 1 } do
        end

        def as_indexed_json(options = {})
          as_json(only: [ :id, :title, :user_id, :is_private ])
        end

        def self.search(query, options = {})
          user_id = options[:user_id]

          settings = {
            query: {
              filtered: {
                query: {
                  multi_match: {
                    fields: ['title'],
                    query: query,
                    fuzziness: 1,
                    prefix_length: 0,
                  }
                },
              }
            },
            filter: {
              "or" => [
                {
                  and: [
                    { term: { user_id: user_id } },
                    { term: { is_private: true } },
                  ]
                },
                {
                  term: { is_private: false }
                },
              ]
            },
          }

          __elasticsearch__.search(settings)
        end
      end
    end
  end
end
