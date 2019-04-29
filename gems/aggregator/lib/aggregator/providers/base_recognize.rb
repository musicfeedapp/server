module Aggregator
  module Providers
    BaseRecognize = Struct.new(:request_attributes) do
      def url
        @url ||= request_attributes[:url]
      end

      def url?
        !url.nil?
      end

      def artist
        @artist ||= request_attributes[:artist]
      end

      def artist?
        !artist.nil?
      end

      def track
        @track ||= request_attributes[:track]
      end

      def track?
        !track.nil?
      end

      def find
        # should be implemented to find by passed url metadata for this song
      end
    end
  end
end
