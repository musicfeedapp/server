module Api
  module AwesomeLogger

    module Helpers
      def logger
        @logger ||= if Rails.env.development?
          Rails.logger
        else
          NullObject.new
        end
      end
    end

    def self.included(base)
      base.class_eval do
        helpers Api::AwesomeLogger::Helpers

        unless Rails.env.production? && Rails.env.test?
          require "awesome_print"

          before do
            file = env['api.endpoint'].source.source_location[0]
            line = env['api.endpoint'].source.source_location[1]
            logger.ap("[api] #{file}:#{line}")
            logger.ap(params)
          end
        end
      end
    end

  end
end

