class AttendanceWeekdaySet < ActiveRecord::Base
  belongs_to :batch
  belongs_to :weekday_set
end
