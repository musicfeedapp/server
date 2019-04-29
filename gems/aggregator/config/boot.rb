# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'rspotify'
require 'sidekiq'
require 'koala'
require 'yourub'
require 'soundcloud'
require 'yt'
require 'le'
require 'retriable'

# We should preload settings.yml before to initialize libraries.
require 'aggregator/settings'
require 'aggregator/facebook_applications'

# We should run initializers files after Rails loads properly, some of the
# libraries depends on the web framework is using specific loader inside.
Dir[Settings.root_path.join('config', 'initializers', '*.rb')].each do |file|
  require file
end

require Settings.root_path.join('lib', 'aggregator.rb')

Aggregator::Boot.setup
