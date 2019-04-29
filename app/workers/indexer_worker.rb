class IndexerWorker
  include Sidekiq::Worker

  def perform(klass, operation, id)
    ids = Array(id)

    klass = Object.const_get(klass)

    client = klass.__elasticsearch__.client

    ids.each do |record_id|
      begin
        case operation.to_s
          when /index/
            record = klass.find(record_id)

            unless client.indices.exists(index: klass.index_name)
              client.indices.create(
                index: klass.index_name,
                body: { settings: klass.settings.to_hash, mappings: klass.mappings.to_hash }
              )
            end

            client.index index: klass.index_name, type: klass.name.downcase, id: record.id, body: record.as_indexed_json
          when /delete/
            record.__elasticsearch__.delete_document
          else raise ArgumentError, "Unknown operation '#{operation}'"
        end
      rescue => boom
        Rails.logger.error boom.message
      end
    end
  end
end
