module Api
  module Client
    VERSION = '0.0.1'
    module V1 ; end
  end
end


require_relative 'client/v1/request_auth'
require_relative 'client/v1/auth'
require_relative 'client/v1/users'
require_relative 'client/v1/songs'
require_relative 'client/v1/proposals'
require_relative 'client/v1/timelines'
require_relative 'client/v1/profile'
require_relative 'client/v1/intro'
require_relative 'client/v1/comments'
require_relative 'client/v1/itunes'
require_relative 'client/v1/playlists'
require_relative 'client/v1/search'

require_relative 'client/v1/facebook_client'
require_relative 'client/v1/base'

require_relative 'client/v2/profile'
require_relative 'client/v2/search'
require_relative 'client/v2/suggestions'
require_relative 'client/v2/comments'
require_relative 'client/v2/proposals'
require_relative 'client/v2/base'

require_relative 'client/v3/search'
require_relative 'client/v3/profile'
require_relative 'client/v3/notifications'
require_relative 'client/v3/base'

require_relative 'client/v4/unsigned'
require_relative 'client/v4/itunes'
require_relative 'client/v4/base'

require_relative 'client/v5/genres'
require_relative 'client/v5/contact_list'
require_relative 'client/v5/phone_artists'
require_relative 'client/v5/publisher'
require_relative 'client/v5/suggestions'
require_relative 'client/v5/users'
require_relative 'client/v5/base'

require_relative 'client/spotify'
require_relative 'client/server'
