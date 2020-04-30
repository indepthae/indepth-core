class SchoolStat < ActiveRecord::Base
  serialize :live_stats
  belongs_to :admin_user
end
