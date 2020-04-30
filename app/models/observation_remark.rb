class ObservationRemark < ActiveRecord::Base
  belongs_to :observation
  validates_presence_of :remark
  default_scope :order=>'id desc'
end
