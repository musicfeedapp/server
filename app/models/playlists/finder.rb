module Playlists
  class Finder
    DEFAULT_SCOPE = -> { Playlist }

    def self.find_by_id(id, options = {})
      scoped = options.fetch(:scoped) { DEFAULT_SCOPE }

      case id
      when 'default' then yield(Default)
      when 'likes' then yield(Likes)
      else
        scoped.call.find_by_id(id)
      end
    end
  end
end
