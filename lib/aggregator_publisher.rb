class AggregatorPublisher
  def self.publish(attributes)
    publisher = AggregatorPublisher.new(attributes)
    publisher.publish
  end

  attr_reader :attributes, :user_identifier, :artist_identifier, :to

  def initialize(attributes)
    @attributes = attributes.stringify_keys

    @user_identifier = @attributes.delete('user_identifier')
    @artist_identifier = @attributes.delete('artist_identifier')

    @attributes.delete('author')
    @attributes.delete('author_picture')

    @to = @attributes.delete('to').to_a
  end

  def logger
    LOGGER
  end

  def user
    @user ||= begin
                facebook_ids = [user_identifier].concat(to)

                facebook_ids.map do |id|
                  User.find_by_facebook_id(id)
                end
              end
  end

  def artist
    @artist ||= begin
                  facebook_ids = [artist_identifier].concat(to)

                  facebook_ids.map do |id|
                    User.artist.find_by_facebook_id(id)
                  end
                end
  end

  def publish
    attributes.deep_stringify_keys!

    logger.debug("[StorageWorker] called plugin with #{attributes.inspect}")

    users = [].concat(user).concat(artist).compact

    response, timeline = PublisherTimeline.find_or_create_for(users, Timeline.new(attributes))

    unless response
      # TODO: we should notify probably rabbitmq channel for showing it later
      # in the logs or somewhere else about the issues on creating the posts.
      [response, timeline]
    else
      response = if timeline.new_record? || (timeline.changed? && timeline.persisted?)
                   timeline.save
                 elsif timeline.persisted?
                   true
                 end

      [response, timeline]
    end
  end

end
