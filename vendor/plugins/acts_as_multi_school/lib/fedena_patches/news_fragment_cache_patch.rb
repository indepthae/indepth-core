module FedenaPatches
  module NewsFragmentCachePatch
    def self.included(base)
      base.instance_eval do
        def cache_fragment_name
          "School_#{MultiSchool.current_school.id}_news_latest"
        end
      end
    end
  end
end