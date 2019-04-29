module Api
  module Client
    module V5
      class PhoneArtists < Grape::API
        version 'v5', using: :path
        format :json

        include RequestAuth

        resources :phone_artists do
          helpers do
            def names
              phone_artists = current_user.phone_artists
              phone_artists = phone_artists.map{ |phone_artist| phone_artist['name'] }
            end

            def search_artists(options={})
              current_user
                .multiple_artist_search(names, options)
                .records
            end
          end

          desc "Search list of artists against saved artist phone list"
          get '/', rabl: 'v5/phone_artists/index' do
            @artists = search_artists({ prevent_followed_users: true })
            @artists = @artists.includes(:genres)
                        .joins("LEFT JOIN user_followers ON user_followers.followed_id = users.id AND user_followers.follower_id=#{current_user.id}")
                        .select <<-SQL
                          DISTINCT ON(users.id) users.*,
                          user_followers.created_at AS followed_at,
                          CASE
                            WHEN user_followers.id IS NULL THEN false
                            ELSE true
                          END AS is_followed,
                          ARRAY(
                            SELECT genres.name FROM user_genres
                            INNER JOIN genres ON genres.id=user_genres.genre_id
                            WHERE user_genres.user_id=users.id
                          ) AS genres_names
                        SQL
                        .squish
          end


          desc "Save the list of phone_artists and return matched artists against them"
          params do
            optional :phone_artists, type: Array[Hash], desc: 'Array of dictionaries containting name of artist that will come from client', default: []
            optional :auto_follow, type: Boolean, default: true
          end
          post '/', rabl: 'v5/phone_artists/index' do
            phone_artists = params[:phone_artists].select(&:present?)

            return @artists = [] if phone_artists.blank?

            current_user.update_attributes(phone_artists: phone_artists)
            @artists = search_artists

            if @artists.present? && params[:auto_follow]
              current_user.bulk_follow!(@artists.pluck(:id), follow_user: true)
            end

            @artists = @artists
                        .joins("LEFT JOIN user_followers ON user_followers.followed_id = users.id AND user_followers.follower_id=#{current_user.id}")
                        .select <<-SQL
                          DISTINCT ON(users.id) users.*,
                          user_followers.created_at AS followed_at,
                          CASE
                            WHEN user_followers.id IS NULL THEN false
                            ELSE true
                          END AS is_followed,
                          ARRAY(
                            SELECT genres.name FROM user_genres
                            INNER JOIN genres ON genres.id=user_genres.genre_id
                            WHERE user_genres.user_id=users.id
                          ) AS genres_names
                        SQL
                        .squish
          end
        end
      end
    end
  end
end
