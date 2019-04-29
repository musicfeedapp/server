module Facebook
  module Proposals

    UsersCreation = Struct.new(:collection) do
      def created_facebook_ids
        @created_facebook_ids ||= []
      end

      def build!(allowed_ids, options)
        collector = []

        collection.each do |attributes|
          next unless allowed_ids.include?(attributes['id'])
          next if collector.include?(attributes['id'])

          collector.push(attributes['id'])

          created_facebook_ids.push(attributes['id'])

          user_attributes = UserAttributes.new(attributes)
          
          LOGGER.debug("[Facebook-UsersCreation] categories: #{ [{id: user_attributes.id, category: user_attributes.category}].inspect }") 
          
          values.push(user_attributes.to_values(options))
        end
      end

      def values
        @values ||= []
      end

      def self.create
        values = []

        yield(values)

        return unless values.present?

        sql = <<-SQL
          INSERT INTO users (
            "name",
            "first_name",
            "last_name",
            "middle_name",
            "facebook_id",
            "facebook_link",
            "facebook_profile_image_url",
            "username",
            "email",
            "user_type",
            "is_verified",
            "ext_id",
            "category",
            "created_at"
          ) VALUES
            #{values.join(", ")}
            returning id,category;
        SQL

        User.connection.execute(sql.squish)
      end
    end

  end
end
