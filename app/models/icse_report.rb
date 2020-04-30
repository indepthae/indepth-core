class IcseReport < ActiveRecord::Base
  belongs_to :batch
  belongs_to :exam
  belongs_to :student
end
