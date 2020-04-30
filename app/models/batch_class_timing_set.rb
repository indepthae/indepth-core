class BatchClassTimingSet < ActiveRecord::Base
  belongs_to :weekday
  belongs_to :batch
  belongs_to :class_timing_set
  validate :class_timing_set_exists #, :presence => true
  named_scope :default,:conditions=>"batch_id IS NULL"

  def class_timing_set_exists
    if ClassTimingSet.find_by_id(self.class_timing_set_id).nil?
      errors.add("class timing set not present")
      return false
    end
  end
end
