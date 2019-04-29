require_relative 'feed/hourly_artist_worker'
require_relative 'feed/artist_worker'
require_relative 'feed/user_worker'

module Facebook
  class FacebookClientError < Exception ; end

  module Feed ; end
end
