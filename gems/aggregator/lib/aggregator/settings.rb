# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'simple-conf'

class Settings
  def self.env
    ENV.fetch('RACK_ENV', 'production')
  end

  def self.development?
    env == 'development' || env == 'test'
  end

  def self.debug
    development? && binding.pry
  end

  include SimpleConf

  Joinable = Struct.new(:path) do
    def join(*relative)
      File.join(path, *relative)
    end
  end

  def self.root_path
    Joinable.new(File.join(File.dirname(File.expand_path(__FILE__)), '..', '..'))
  end
end
