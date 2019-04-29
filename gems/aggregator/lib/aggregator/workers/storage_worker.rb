# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Workers

    class StorageWorker
      include Sidekiq::Worker

      sidekiq_options queue: :storage, retry: 5

      def perform(id)
        LOGGER.debug("[StorageWorker] enabled plugins: #{Aggregator.plugins(:storage).inspect}")

        timeline = Aggregator.client.get(id)

        Aggregator.plugins(:storage).each do |plugin_klass|
          LOGGER.debug("[StorageWorker] calling plugin: #{plugin_klass.inspect} with #{timeline.inspect}")

          instance = plugin_klass.new
          instance.perform(timeline)
        end
      ensure
        Aggregator.client.del(id)
      end
    end

  end
end
