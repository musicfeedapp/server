module Aggregator
  module Recognize

    Itunes = Struct.new(:artist_name, :track_name) do
      def link
        @link ||= Aggregator::Search::ItunesSearch.search(artist_name, track_name)
      end

      def valid?
        !link.nil?
      end

      def attributes
        return {} unless valid?

        { link: link }
      end
    end

  end
end
