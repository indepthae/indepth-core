# === Using asset timestamps
# in order to work caching, all your application servers must
# return the same timestamps for assets. This means that they must have their clocks
# synchronized. If one of them drifts out of sync, you'll see different
# timestamps at random and the cache won't work. In that case the browser
# will request the same assets over and over again even thought they didn't
# change. so we changed timestamps to digest md5 value of respective assset file

module ActionView
  module Helpers
    module AssetTagHelper

      private
      def rails_asset_id(source)
        if asset_id = ENV["RAILS_ASSET_ID"]
          asset_id
        else
          if @@cache_asset_timestamps && (asset_id = @@asset_timestamps_cache[source])
            asset_id
          else
            path = File.join(ASSETS_DIR, source)
            asset_id = File.exist?(path) ? Digest::MD5.hexdigest(File.read(path)) : ''
            if @@cache_asset_timestamps
              @@asset_timestamps_cache_guard.synchronize do
                @@asset_timestamps_cache[source] = asset_id
              end
            end
            asset_id
          end
        end
      end
    end
  end
end