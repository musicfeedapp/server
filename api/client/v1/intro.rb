class Api::Client::V1::Intro < Grape::API
  format :json

  include RequestAuth

  resource :intro do
    get '/', rabl: 'v1/intro/show' do
      # nothing
    end
  end

end

