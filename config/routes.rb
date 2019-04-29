require 'sidekiq/web'

require File.expand_path(File.join(Rails.root, 'api/api.rb'))

Rails.application.routes.draw do
  devise_for :users, controllers: { passwords: "passwords" }

  get '/open_app' => "home#open_app", as: :open_app

  resources :users, only: :show

  resources :dashboard, only: :index

  # You can have the root of your site routed with "root"
  root 'dashboard#index'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'admin' && password == 'admin-awesome'
  end
  mount Sidekiq::Web, at: "/sidekiq"

  namespace :api do
    mount Api::Client::Server => "/client"
  end
end
