module Searchable
  module TimelineExtension
    def self.included(base)
      base.class_eval do
        index_name "timelines-#{Rails.env}"

        settings index: { number_of_shards: 1 } do
        end

        def as_indexed_json(options = {})
          as_json(only: [ :id, :name, :artist, :description ])
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

          __elasticsearch__.search(settings)
        end
      end
    end
  end
end
