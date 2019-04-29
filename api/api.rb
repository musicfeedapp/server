Rabl.register!

Rabl.configure do |config|
  config.include_json_root = false
end

require_relative 'awesome_logger'
require_relative 'client'

Dir[Rails.root.join('lib', '*.rb')].each do |file|
  require file
end

Dir[Rails.root.join('app', 'workers', '*.rb')].each do |file|
  require file
end

Dir[Rails.root.join('app', 'models', '*.rb')].each do |file|
  require file
end

Dir[Rails.root.join('app', 'services', '*.rb')].each do |file|
  require file
end

Dir[Rails.root.join('app', 'mailers', '*.rb')].each do |file|
  require file
end

module Api
end

