module Api
  module Client
    module V5

      class ContactList < Grape::API
        version 'v5', using: :path
        format :json

        include RequestAuth

        resources :contacts do
          desc "Save the contact list for user and search against that list"
          params do
            requires :contact_list, type: Array[Hash], desc: 'Array of dictionaries containting email and contact numbers of users contacts'
            optional :auto_follow, type: Boolean, default: true
          end
          post '/', rabl: 'v5/contacts/index' do
            return @users = [] if params['contact_list'].blank?

            current_user.update_attributes(contact_list: params['contact_list'])
            @users = current_user.search_contacts.records || []

            if @users.present? && params[:auto_follow]
              current_user.bulk_follow!(@users.map(&:id), follow_user: true)
            end

            @users = @users
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

