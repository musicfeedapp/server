require 'faraday'

class NewMissingCategoriesWorker
  include Sidekiq::Worker

  # include Sidetiq::Schedulable
  # recurrence { hourly }

  class NewMissingCategoriesMigrationNodeWorker
    include Sidekiq::Worker

    def perform(facebook_ids)
      facebook_ids.each do |facebook_id|
        begin
          access_token = Aggregator::FacebookApplicationQueue.next
          response = Faraday.get("https://graph.facebook.com/#{facebook_id}", fields: "id,category", access_token: access_token)
          error_format = /\APage ID (\d*) was migrated to page ID (\d*)./

          attributes = JSON.parse(response.body)
          if attributes['error'].present? && attributes['error']['code'] == 21
            error_match = error_format.match(attributes['error']['message'])
            next unless error_match

            User.connection.execute(<<-SQL
              UPDATE users SET facebook_id='#{error_match.captures[1]}' WHERE users.facebook_id='#{facebook_id}'
            SQL
            .squish)

            Timeline.connection.execute(<<-SQL
              UPDATE timelines SET artist_identifier='#{error_match.captures[1]}' WHERE timelines.user_identifier='#{facebook_id}' OR timelines.artist_identifier='#{facebook_id}'
            SQL
            .squish)
          elsif attributes['error'].present? && attributes['error']['code'] != 21 && attributes['category'].blank?
            begin
              artist = User.find_by_facebook_id(facebook_id)
              ArtistCategory.new(artist, attributes['error']['message']).move_artist
            rescue => boom
              Notification.error(boom, facebook_id: facebook_id)
            end
          else
            next unless attributes['category'].present?

            User.connection.execute(<<-SQL
              UPDATE users SET category='#{attributes['category']}' WHERE users.facebook_id='#{facebook_id}'
            SQL
            .squish)
          end
        rescue => boom
          Notification.error(boom, facebook_id: facebook_id)
        end
      end
    end
  end

  NUMBER_OF_USERS = 40000
  NODE_NUMBER_OF_USERS = 1000

  def perform
    User.artist.where(category: nil).limit(NUMBER_OF_USERS).pluck(:facebook_id).each_slice(NODE_NUMBER_OF_USERS) do |collection|
      NewMissingCategoriesMigrationNodeWorker.perform_async(collection)
    end
  end
end
