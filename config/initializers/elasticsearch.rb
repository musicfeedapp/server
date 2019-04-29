class Settings
  def self.config_file_name
    'settings'
  end

  include SimpleConf
end

config = {
  host: Settings.elasticsearch.host,
  transport_options: {
    request: { timeout: Settings.elasticsearch.timeout }
  },
}

Elasticsearch::Model.client = Elasticsearch::Client.new(config)
