module Facebook
  module Proposals

    UserAttributes = Struct.new(:attributes) do
      def initialize(attributes)
        super(attributes)

        @first_name, @last_name, @middle_name = name.split(' ')
      end

      attr_reader :first_name, :last_name, :middle_name

      def username
        if attributes['username'].blank?
          Usernameable.get(attributes['name'])
        else
          attributes['username']
        end
      end

      def picture
        "http://graph.facebook.com/#{attributes['id']}/picture?type=large"
      end

      def email
        if attributes['email'].blank?
          "#{attributes['id']}@facebook.com"
        else
          attributes['email']
        end
      end

      def name
        @name ||= quote_string(attributes['name'])
      end

      def id
        attributes['id']
      end

      def category
        attributes['category']
      end

      def now
        @now ||= DateTime.now.utc.to_s(:db)
      end

      def to_values(options = {})
        user_type = options.fetch(:user_type) { options.fetch('user_type') { 'user' } }
        token = SecureRandom.urlsafe_base64(25).tr('lIO0', 'sxyz')
        "('#{name}', '#{first_name}', '#{last_name}', '#{middle_name}', '#{id}', 'https://www.facebook.com/#{id}', '#{picture}', '#{username}', '#{email}', '#{user_type}', '#{attributes['is_verified']}', '#{token}', '#{category}', '#{now}')"
      end

      def quote_string(s)
        s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
      end
    end

  end
end
