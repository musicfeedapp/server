module Suggestions
  def refresh
    ActiveRecord::Base.connection.execute <<-SQL
      REFRESH MATERIALIZED VIEW suggestions.artists;
      REFRESH MATERIALIZED VIEW suggestions.trending_artists;
    SQL
  end
  module_function :refresh
end
