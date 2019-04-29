class Api::Client::V1::Search < Grape::API
  format :json

  include RequestAuth

  resource :search do
    params do
      optional :keywords, type: String
    end
    get '/', rabl: 'v1/search/index' do
      @collections = { artists: [], users: [] }
    end
  end
end

