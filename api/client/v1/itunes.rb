class Api::Client::V1::Itunes < Grape::API
  format :json

  include RequestAuth

  helpers do
    def tracks
      JSON.parse(params[:tracks].to_s).to_a
    end

    def names
      tracks
        .group_by { |track| track['artist'] }
        .keys
    end
  end

  resource :itunes do
    post '/' do
      names.each do |name|
        UserArtistInfoWorker.perform_async(current_user.id, name)
      end
    end
  end

end
