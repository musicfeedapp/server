module ElasticsearchSearchable

  def self.included(base)
    base.class_eval do
      require 'elasticsearch/model'
      include Elasticsearch::Model

      include Elasticsearch::Model::Indexing

    end
  end

end
