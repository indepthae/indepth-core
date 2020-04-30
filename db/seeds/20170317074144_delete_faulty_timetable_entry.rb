require 'logger'  
log = Logger.new('log/update_timetable_entries.log')
tte_ids = []
log.info('======================================================')
log.info('++++++++++++++++++++++++++++++++++++++++++++++++++++++')
sch_faulty_entry_count = 0
sch_issue_entries_count = 0
sch_attendance_count = 0
if (MultiSchool rescue nil)
  schools = School.all(:order=>"id desc")
  schools.each do |school|
    stte_ids = []
    faulty_entry_count = 0
    issue_entries_count = 0
    attendance_count = 0
    log.info("School :: #{school.id}")
    MultiSchool.current_school = school
    timetables = Timetable.all
    timetables.each do |timetable|
      ttcts = timetable.time_table_class_timings.all(:include => :batch,:conditions=>["batch_id is not null"])
      batches = ttcts.collect {|x| x.batch }
      batches.each do |batch|
        ttct = ttcts.select {|x| x.batch_id == batch.id }.first
        ttct_s = ttct.time_table_class_timing_sets
        ttes = timetable.timetable_entries.all(:conditions => {:batch_id => batch.id}, :include => :class_timing)
        ttes.each do |tte|
          t_wk = tte.weekday_id
          t_ct = tte.class_timing
          tt_ct = ttct_s.select {|x| x.weekday_id == t_wk && x.batch_id == batch.id }.last
          if tt_ct.present?
            if tt_ct.class_timing_set_id != t_ct.class_timing_set_id
              tte_ids << tte.id
              stte_ids << tte.id
              faulty_entry_count = faulty_entry_count.next
              log.info("#{school.id} : #{tte.timetable_id} #{tte.id} - #{timetable.range}") if tt_ct.class_timing_set_id != t_ct.class_timing_set_id                              
              tte_sl = SubjectLeave.find_all_by_batch_id_and_class_timing_id(batch.id,t_ct.id, :conditions => "month_date between #{timetable.start_date} and #{timetable.end_date}").select {|x| x.month_date.to_date.wday == t_wk}
              if tte_sl.present?
                attendance_count = attendance_count + tte_sl.compact.length
                puts "#{tt_sl.map(&:id).join(',')}"
                log.info("#{tt_sl.map(&:id).join(',')}")
              end
            end
          else
            stte_ids << tte.id
            issue_entries_count = issue_entries_count.next
            log.info("#{tte.id} - #{timetable.range} - #{school.id} -- tt_ct not present")                              
            tte_sl = SubjectLeave.find_all_by_batch_id_and_class_timing_id(batch.id,t_ct.id, :conditions => "month_date between #{timetable.start_date} and #{timetable.end_date}").select {|x| x.month_date.to_date.wday == t_wk}
            if tte_sl.present?
              attendance_count = attendance_count + tte_sl.compact.length
              puts "#{tt_sl.map(&:id).join(',')}"
              log.info("#{tt_sl.map(&:id).join(',')}")
            end                      
          end
        end
      end			
    end
        
    log.info("school :: #{school.id} -  faulty_entry_count : #{faulty_entry_count}")
    log.info("school :: #{school.id} -  issue_entries_count : #{issue_entries_count}")
    log.info("school :: #{school.id} -  attendance_count : #{attendance_count}")
    sch_faulty_entry_count += faulty_entry_count
    sch_issue_entries_count += issue_entries_count
    sch_attendance_count += attendance_count
    TimetableEntry.delete_all("id in (#{stte_ids.join(',')})") if stte_ids.present?
    log.info("Deleted #{stte_ids.length} timetable entries id :: #{stte_ids.join(',')}")
  end   
  log.info("Total -  faulty_entry_count : #{sch_faulty_entry_count}")
  log.info("Total -  issue_entries_count : #{sch_issue_entries_count}")
  log.info("Total -  attendance_count : #{sch_attendance_count}")
  log.info("No of tte to update is : #{tte_ids.length}")
  #  log.info("tte is : #{tte_ids.join(',')}")
  log.info("Deleted #{tte_ids.length} timetable entries")
  log.info('-------------------------------------------------------------------------------------------------------------------------------------------------')
end     