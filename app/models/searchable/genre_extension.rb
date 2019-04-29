module Searchable
  module GenreExtension

    def self.included(base)
      base.class_eval do
        index_name "genres-#{Rails.env}"

        settings index: { number_of_shards: 1 } do
        end

        def as_indexed_json(options = {})
          as_json(only: [ :id, :name ])
        end

        def self.search(query)
          settings = {
            query: {
              filtered: {
                query: {
                  multi_match: {
                    fields: ['name'],
                    query: query,
                    fuzziness: 1,
                    prefix_length: 0,
                  }
                },
              }
            },
            filter: {},
          }

          __elasticsearch__.search(settings).records
        end
      end
    end
  end
end
