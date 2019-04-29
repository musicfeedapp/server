module Aggregator
  module Providers
    module Soundcloud

      module Link
        module_function

        def id(link)
          return link if link.include?("soundcloud.com")
        end

        def link(id)
          id
        end
      end

    end
  end
end
