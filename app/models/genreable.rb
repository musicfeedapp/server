module Genreable

  def self.included(base)
    base.class_eval do
      has_many :user_genres
      has_many :genres, through: :user_genres

      def create_user_genre!(genre_ids)
        user_id = self.id

        UserGenre.where(user_id: user_id).delete_all

        if genre_ids.size > 0
          genre_ids = genre_ids.map{ |genre_id| "(#{user_id}, #{genre_id})" }

          UserGenre.connection.execute(<<-SQL
            INSERT INTO user_genres("user_id", "genre_id")
            VALUES
            #{genre_ids.join(", ")}
          SQL
          .squish)
        end

        self.genres
      end

      extend Genreable::ClassMethods
    end
  end

  module ClassMethods

    def top_genres(limit=100)
      Genre.where(<<-SQL 
                    id IN ( SELECT genre_id FROM user_genres 
                            GROUP BY genre_id ORDER BY Count(*) 
                            DESC Limit #{limit}
                          )
                  SQL
        .squish)
    end

    def create_genres!(genres)
      names = Genre.where(name: genres.map!(&:downcase)).pluck(:name)
      genres = genres - names
      genres = genres.map{ |genre| "('#{genre}')" }
      return [] if genres.blank?

      result = Genre.connection.execute(<<-SQL
                 INSERT INTO genres("name")
                 VALUES
                 #{genres.join(", ")}
                 returning id;
               SQL
        .squish)

      result.to_a
    end
  end
end
