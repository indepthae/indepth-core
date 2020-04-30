class DelayedTimetableSummaryGenerate

  def initialize(timetable)
    @timetable_id = timetable.id
    timetable.update_attribute(:timetable_summary_status,2)
  end
  
  def perform
    @timetable = Timetable.find(@timetable_id, :include =>
        {:time_table_class_timings =>
          {:batch => [
            {:course => :batches},
            {:weekday_set => :weekday_sets_weekdays},
            :timetable_entries,
            {:subjects => [:elective_group,:employees]},
            { :elective_groups => :subjects },
            {:batch_class_timing_sets => {:class_timing_set => :class_timings}}
          ] }})
    @timetable.update_timetable_summary
  end
end