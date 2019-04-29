module Aggregator
  module Providers
    module Shazam

      module Link
        module_function

        def id(link)
          return link if link.include?("shazam.com")
        end

        def link(id)
          id
        end
      end

    end
  end
end
