class TimeTableClassTiming < ActiveRecord::Base
  belongs_to :batch
  belongs_to :timetable
  belongs_to :class_timing_set
  has_many :time_table_class_timing_sets, :dependent => :destroy

  validates_presence_of :batch_id
  
  after_save  :update_timetable_summary_status
  after_destroy :update_timetable_summary_status

  def update_timetable_summary_status
    Timetable.mark_summary_status({:model => self}) if self.changed.present?
  end
  
end
