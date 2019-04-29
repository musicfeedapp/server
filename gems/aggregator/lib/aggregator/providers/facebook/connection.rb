# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'koala'

module Aggregator
  module Providers
    module Facebook

      BATCH_SIZE = 50

      module Connection
        #
        # @note Base class should implement methods user and who
        #
        def facebook
          @facebook ||= Koala::Facebook::API.new(auth_token)
        end

        # TODO: replace it by outside method for getting auth token and searching it.
        def auth_token
          raise 'should be implemented'
        end

        def iteratable(ids)
          Enumerator.new do |y|
            step = 0
            while (pickable = ids[step..(step + BATCH_SIZE - 1)]).to_a.size > 0
              y << pickable
              step = step + BATCH_SIZE
            end
          end
        end

        def objects_for(ids)
          iteratable(ids).map do |pickable|
            begin
              facebook.batch do |api|
                pickable.map do |id|
                  begin
                    api.get_object(id, {}, api_version: 'v2.3')
                  rescue => boom
                    Notification.notify(boom, method_name: 'objects_for', facebook_id: id)
                    raise boom
                  end
                end
              end
            rescue => boom
              Notification.notify(boom, method_name: 'objects_for', ids: ids)
i           end
          end
        end

        def conn
          @conn ||= if Settings.respond_to?(:faraday)
                      Faraday.new(:url => 'https://graph.facebook.com', ssl: { verify: true }) do |req|
                        req.adapter :net_http
                        req.proxy Settings.faraday.proxy_url
                        req.options.timeout = 60
                      end
                    else
                      Faraday.new(:url => 'https://graph.facebook.com', ssl: { verify: true }) do |req|
                        req.adapter :net_http
                        req.options.timeout = 60
                      end
                    end
        end

        def collector_for(action_name)
          access_token = Aggregator::FacebookApplicationQueue.next

          begin
            connections = if who == 'me'
              facebook.get_connections(who, action_name, { api_version: 'v2.3' })
            else
              response = conn.get("/#{who}/#{action_name}&access_token=#{access_token}")
              response = eval(response.body)
              response.has_key?(:data) ? response[:data] : []
            end

            read_all(connections)
          rescue Koala::Facebook::AuthenticationError
            # TODO: nothing to do with that user requires to authorize again
            # probably we should mark somehow the users to make reauthorization
            # in the next time.
          rescue => boom
            Notification.notify(boom, method_name: 'collector_for', for: 'me', facebook_id: 'me', action_name: action_name, facebook_api: action_name)
            raise boom
          end
        end

        def recent?
          options.fetch(:recent) { options.fetch('recent', true) }
        end

        MAX_PROCESSING = 50

        def read_all(connections)
          enqueue(connections.to_a)

          count = connections.to_a.size
          if recent? && count > MAX_PROCESSING
            return
          end

          begin
            return connections unless connections.respond_to?(:next_page)

            while connections = connections.next_page
              enqueue(connections.to_a)

              count += connections.to_a.size
              if recent? && count > MAX_PROCESSING
                return
              end
            end
          rescue => boom
            Notification.notify(boom, from: "Aggregator::Providers::Facebook::Connection")
            # @note for some reasons facebook api is raising the issues sometimes
            # on paging some of the resouces. we should skip further paginations
            # and continue to review the data.
          end
        end

        def enqueue(collection)
          # We should override it aggregator workers, we should not collect data
          # in memoery.
          raise 'should be implemented'
        end
      end

    end
  end
end
