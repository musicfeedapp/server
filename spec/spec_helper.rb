ENV["RAILS_ENV"] = 'test'

require File.expand_path("../../config/environment", __FILE__)

ActiveRecord::Migration.maintain_test_schema!

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

module AuthHelpers
  def logged_in(role = nil)
    @current_user = create(:user, role: role)
    sign_in(@current_user)
  end

  def current_user
    controller.send(:current_user)
  end
end

module UserMocks
  def create_user(options = {})
    user = mock_model('User', { email: 'user@example.com' }.merge(options.merge(authentications: [])))
    User.stub(:find).with(user.id).and_return(user)
    User.stub(:find_by_email).with(user.email).and_return(user)
    user
  end

  def create_timeline(options = {})
    mock_model('Timeline', { id: 1, name: 'Name 1', link: 'link 1', picture: 'picture 1', album: 'album 1', artist: 'artist 1', likes_count: 1, author: 'Alex Korsak', author_picture: 'http://example.com/korsak.jpeg', youtube_link: "http://www.youtube.com/", published_at: DateTime.now.to_s(:db) }.merge(options))
  end

  def create_authentication_for(user, options = {})
    authentication = mock_model('Authentication', options)
    user.authentications.stub(:find_by_provider).with(options[:provider]).and_return(authentication)
    user.authentications.stub(options[:provider]).and_return(double('provider', auth_token: "#{options[:provider]}-token"))
    authentication
  end

  def create_facebook_authentication_for(user)
    create_authentication_for(user, provider: 'facebook', auth_token: 'auth-token')
  end
end

module ApiAuthHelpers
  def logged_in(user)
    allow(subject).to receive(:current_user) { user }
  end
end

module Fixtures
  def load_fixture(name)
    JSON.parse(File.read(Rails.root.join("spec/fixtures/#{name}.json")))
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.patch_marshal_to_support_partial_doubles = true
  end

  config.raise_errors_for_deprecations!

  config.filter_run_excluding :broken => true

  config.include Devise::TestHelpers, type: :controller
  config.include AuthHelpers,         type: :controller
  config.include FactoryGirl::Syntax::Methods
  config.include ApiHelper,           api: true
  config.include ApiAuthHelpers,      api: true
  config.include Rack::Test::Methods, api: true
  config.include Fixtures

  config.order = "random"

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
end
