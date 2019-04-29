# -*- coding: utf-8 -*-
# encoding: UTF-8

# We are using this list for iterating it.
require 'simple-conf'

class FacebookApplications
  def self.config_file_name
    'applications'
  end

  def self.env
    ENV.fetch('RACK_ENV', 'production')
  end

  def self.development?
    env == 'development'
  end

  def self.debug
    development? && binding.pry
  end

  include SimpleConf
end
