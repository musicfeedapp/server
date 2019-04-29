module Searchable
  module UserExtension
    def self.included(base)
      base.class_eval do
        index_name "users-#{Rails.env}"

        settings index: { number_of_shards: 1 } do
          mappings dynamic: 'false' do
            indexes :id
            indexes :name, type: "multi_field", fields: {
                      name: { type: "string", index: "analyzed" },
                      exact: { type: "string", index: "not_analyzed" }
                    }
            indexes :username, index: 'not_analyzed'
            indexes :email, index: 'not_analyzed'
            indexes :user_type
            indexes :is_verified, type: 'boolean'
            indexes :secondary_phones, index: 'not_analyzed'
          end
        end

        def as_indexed_json(options = {})
          as_json(only: [ :id, :name, :username, :user_type, :is_verified, :email, :secondary_phones ])
        end

        def friend_search(query)
          settings = {
            query: {
              function_score: {
                query: {
                  filtered: {
                    query: {
                      bool: {
                        must: [
                          { multi_match: { fields: ['name', 'username'],
                                           query: query,
                                           fuzziness: 1,
                                           prefix_length: 0,
                                         }
                          }
                        ],
                        should: [
                          { term: { "name.exact": { value: query, boost: 15 } } },
                          { prefix: { "name.exact": { value: query, boost: 10 } } },
                          { match_phrase: { name: { query: query, slop: 0, boost: 5 } } }
                        ]
                      }
                    },
                    filter: { bool: { must: { term: { user_type: 'user' }, }, } },
                    strategy: :leap_frog_filter_first
                  }
                },
                score_mode: :multiply,
                boost_mode: :multiply,
              }
            },
          }
          #  removing the friends search on request of Tyrone Dated 04 Feb 2016
          # else
          #   friends_ids = user_friends.pluck(:friend1_id, :friend2_id).flatten - [id]
          #   friends_of_friends_ids = friends_of_friends.pluck(:friend1_id, :friend2_id).flatten - [id]

          #   settings = {
          #       query: {
          #       function_score: {
          #           query: {
          #             filtered: {
          #               query: {
          #                 bool: {
          #                   must: [ 
          #                     { multi_match: { fields: ['name', 'username'],
          #                                      query: query,
          #                                      fuzziness: 1,
          #                                      prefix_length: 0,
          #                                    }
          #                     }
          #                   ],
          #                   should: [
          #                     { term: { "name.exact": { value: query, boost: 15 } } },
          #                     { prefix: { "name.exact": { value: query, boost: 10 } } },
          #                     { match_phrase: { name: { query: query, slop: 0, boost: 5 } } }
          #                   ]
          #                 }
          #               },
          #               filter: { bool: { must: { term: { user_type: 'user' }, }, } },
          #               strategy: :leap_frog_filter_first
          #             }
          #           },
          #           functions: [
          #           {
          #               filter: { ids: { values: friends_ids } },
          #               weight:  5
          #           },
          #           {
          #               filter: { ids: { values: friends_of_friends_ids } },
          #               weight:  2
          #           },
          #           ],
          #           max_boost: 5,
          #           score_mode: :multiply,
          #           boost_mode: :multiply,
          #       }
          #       },
          #       filter: {
          #       ids: {
          #           values: []
          #           .concat(friends_ids)
          #           .concat(friends_of_friends_ids)
          #           .uniq
          #           }
          #       },
          #       sort: { _score: { order: 'desc' } },
          #   }
          # end

          self.class.__elasticsearch__.search(settings)
        end

        def artist_search(query)
          settings = {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [ 
                      { multi_match: { fields: ['name', 'username'],
                                       query: query,
                                       fuzziness: "AUTO",
                                       prefix_length: 0,
                                     }
                      }
                    ],
                    should: [
                      { term: { "name.exact": { value: query, boost: 15 } } },
                      { prefix: { "name.exact": { value: query, boost: 10 } } },
                      { match_phrase: { name: { query: query, slop: 0, boost: 5 } } }
                    ]
                  }
                },
                filter: {
                  bool: {
                    must: {
                      term: { user_type: 'artist' },
                    },

                    must_not: [
                      {
                        term: { email: "info@musicfeed.co" },
                        term: { username: "musicfeed" },
                        term: { id: "2309391" }
                      },
                    ]
                  } 
                },
                strategy: :leap_frog_filter_first
              }
            }
          }

          self.class.__elasticsearch__.search(settings)
        end

        def multiple_artist_search(names=nil, options={})
          followed_artists_names = if options[:prevent_followed_users].present?
                                     []
                                   else
                                     self.followed.pluck(:name)
                                   end

          if names.blank?
            names = self.phone_artists.map{ |phone_artist| phone_artist["name"] }
          end

          names << names.flatten.map { |artist| artist.split('&#38;') }
          names << names.flatten.map { |artist| artist.split('ft') }
          names << names.flatten.map { |artist| artist.split('ft.') }
          names << names.flatten.map { |artist| artist.split('feat') }
          names << names.flatten.map { |artist| artist.split('Feat') }
          names << names.flatten.map { |artist| artist.split('Feat.') }
          names << names.flatten.map { |artist| artist.split('vs.') }
          names << names.flatten.map { |artist| artist.split('pres.') }
          names << names.flatten.map { |artist| artist.split(',') }

          search_names = []
          search_names << names.flatten.map { |artist| artist + ' music' }
          search_names << names.flatten.map { |artist| artist + ' official' }
          search_names << names

          search_names = search_names.flatten.uniq.map { |artist| artist.squish! }

          settings = {
            query: {
              filtered: {
                filter: {
                  bool: {
                    must: [
                      { term: { user_type: 'artist' } },
                      { terms: { "name.exact": search_names } },
                    ],

                    must_not: { terms: { "name.exact": followed_artists_names } }
                  }
                }
              }
            },
            size: 1000,
          }

          self.class.__elasticsearch__.search(settings).records
        end

        # [ { email: "awais545@gmail.com", contact_number: "03224713082" } ]
        def search_contacts(my_contacts = nil)
          searchable = Hash.new { |h,k| h[k] = [] }

          (my_contacts || self.contact_list).each do |contact|
            contact.deep_stringify_keys!

            searchable[:emails] << contact["email"] if contact['email'].present?
            searchable[:contact_numbers] << contact["contact_number"] if contact['contact_number'].present?
          end

          settings = {
            query: {
              filtered: {
                filter: {
                  bool: {
                    must: [{ term: { user_type: 'user' } }],
                    should: [
                      { terms: { email: searchable[:emails] } },
                      { terms: { contact_number: searchable[:contact_numbers] } },
                      { terms: { secondary_phones: searchable[:contact_numbers] } },
                    ]
                  }
                }
              }
            },
            size: 100,
          }

          self.class.__elasticsearch__.search(settings).records
        end
      end
    end
  end
end
