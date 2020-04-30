class TimeTableClassTimingSet < ActiveRecord::Base
  has_many :class_timings
  belongs_to :class_timing_set
end
