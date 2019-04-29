class Genre < ActiveRecord::Base
  include Genreable

  include ElasticsearchSearchable
  include Searchable::GenreExtension

  after_save { IndexerWorker.perform_async(self.class.name, :index,  id) }
  after_destroy { IndexerWorker.perform_async(self.class.name, :delete, id) }
end

# == Schema Information
#
# Table name: genres
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime
#  updated_at :datetime
#
