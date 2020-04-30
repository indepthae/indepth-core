class StatBookmark < ActiveRecord::Base
  validates_uniqueness_of :url,{:scope=>:admin_user_id}
  belongs_to :admin_user
end
