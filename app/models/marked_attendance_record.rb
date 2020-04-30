class MarkedAttendanceRecord < ActiveRecord::Base
  belongs_to :batch
  belongs_to :subject
  belongs_to :academic_year

  validates_presence_of :month_date,:batch_id, :saved_date

  def self.dailywise_locked_dates(batch_id)
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    attendances = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and is_locked = ? and attendance_type = ?",academic_year_id, batch_id, true, 'Daily']).collect(&:month_date)
    return  attendances
  end

  def self.subjectwise_locked_dates(batch_id,subject_id)
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    attendance_dates = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and is_locked = ? and attendance_type = ? and subject_id = ?", academic_year_id, batch_id, true, 'SubjectWise',subject_id])
    attendances = {}
    attendance_dates = attendance_dates.group_by(&:class_timing_id)
    attendance_dates.each do |class_timing_id,attendance|
      attendances[class_timing_id] = {}
      attendances[class_timing_id] = attendance.collect(&:month_date)
    end
    return attendances
  end

  def self.auto_lock_saved_records
    #  academic_year_id = AcademicYear.fetch_academic_year_id
    today_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    attendance_type =  Configuration.get_config_value('StudentAttendanceType')
    lock_duration = Configuration.get_config_value('AttendanceLockDuration')
    if lock_duration.present?
      lock_duration = lock_duration.to_i
      end_lock_date = today_date - lock_duration
      start_lock_date = end_lock_date - lock_duration
      lock_saved_records(attendance_type,start_lock_date,end_lock_date,today_date)
    end
  end


  def self.lock_saved_records(attendance_type,start_lock_date,end_lock_date,today_date)
    attendances = MarkedAttendanceRecord.all(:conditions => ["(is_locked is null or is_locked = ?) and attendance_type = ? and month_date between ? and ?  " , false,attendance_type,start_lock_date,end_lock_date])
    attendances.each do |attendance|
      attendance.update_attributes(:is_locked => true, :locked_by => 0,:locked_date => today_date)
    end
  end

  def self.auto_lock_duration
    today_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    lock_duration = Configuration.get_config_value('AttendanceLockDuration')
    if lock_duration.present?
      lock_duration = lock_duration.to_i
      lock_date = today_date - (lock_duration * 2)
      return lock_date
    end
  end

  def self.fetch_saved_dates(batch_id, subject_id = nil)
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    attendance_type =  Configuration.get_config_value('StudentAttendanceType')
    if attendance_type == 'Daily'
      attendance_dates = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ?" ,academic_year_id, batch_id,attendance_type])
      attendances = attendance_dates.collect(&:month_date)
    elsif attendance_type == 'SubjectWise'
      attendances = {}
      attendance_dates = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id = ?" ,academic_year_id, batch_id,attendance_type,subject_id])
      attendance_dates = attendance_dates.group_by(&:class_timing_id)
      attendance_dates.each do |class_timing_id,attendance|
        attendances[class_timing_id] = {}
        attendances[class_timing_id] = attendance.collect(&:month_date)
      end
    end
    return attendances
  end

  def self.dailywise_working_days(batch_id)
    batch = Batch.find(batch_id)
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    batch_holiday_set = batch.holiday_event_dates.map(&:to_s)
    attendance =  MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ?",academic_year_id,batch_id,'Daily']).collect(&:month_date)
    attendance = attendance.reject{|cp| batch_holiday_set.include?(cp.to_s)}
  end

 
  def self.subject_wise_working_days(batch,subject_id = nil)
    batch_holiday_set = batch.holiday_event_dates.map(&:to_s)
    academic_year_id = Attendance.fetch_academic_year(batch.id)
    if subject_id.present?
      save_attendace = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id = ? ",academic_year_id,batch.id,'SubjectWise', subject_id])
    else
      save_attendace = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ?",academic_year_id,batch.id,'SubjectWise'])
      elective_groups = batch.elective_groups.active
      elective_groups.each do |elective_group|
        group_subjects_ids = elective_group.subjects.active.collect(&:id)
        save_attendace = save_attendace.reject{|x| group_subjects_ids.include?(x.subject_id)}
      end
      save_attendace = save_attendace.reject{|cp| batch_holiday_set.include?(cp.month_date.to_s)}
      save_attendace = save_attendace.collect(&:month_date)
    end
    return save_attendace
  end
  
  def self.overall_subject_wise_working_days(batch)
    batch_holiday_set = batch.holiday_event_dates.map(&:to_s)
    academic_year_id = Attendance.fetch_academic_year(batch.id)
    save_attendace = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ?",academic_year_id,batch.id,'SubjectWise'])
    elective_groups = batch.elective_groups.active
    elective_groups.each do |elective_group|
      group_subjects_ids = elective_group.subjects.active.collect(&:id)
      save_attendace = save_attendace.reject{|x| group_subjects_ids.include?(x.subject_id)}
    end
    save_attendace = save_attendace.reject{|cp| batch_holiday_set.include?(cp.month_date.to_s)}
    return save_attendace
  end
  
  def self.subject_wise_elective_working_days(batch_id,elective_group)
    batch = Batch.find(batch_id)
    batch_holiday_set = batch.holiday_event_dates.map(&:to_s)
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    group_subjects_ids = elective_group.subjects.active.collect(&:id)
    save_attendance = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id IN (?)",academic_year_id,batch_id,'SubjectWise',group_subjects_ids]).reject{|cp| batch_holiday_set.include?(cp.month_date.to_s)}.collect{|v| [v.month_date ,v.class_timing_id]}.uniq
    save_date = []
    save_attendance.each do |date|
      save_date << date[0]
    end
    return save_date
  end

  def self.subject_wise_tt_working_days(batch,subject_id)
    batch_holiday_set = batch.holiday_event_dates.map(&:to_s)
    academic_year_id = Attendance.fetch_academic_year(batch.id)
    save_attendace = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id = ? ",academic_year_id,batch.id,'SubjectWise', subject_id])
    save_attendace = save_attendace.reject{|cp| batch_holiday_set.include?(cp.month_date.to_s)}
    return save_attendace
  end
  
  def self.day_wise_working_days(batch,date)
    MarkedAttendanceRecord.all(:conditions => ["attendance_type = ? and batch_id =? and month_date = ? ",'Daily',batch.id,date])
  end
  
  def self.daywise_total_save_days(date)
    MarkedAttendanceRecord.all(:conditions => ["attendance_type = ? and month_date = ? ",'Daily',date])
  end
  
  def self.elective_subject_working_days(batch,elective_subjects = nil)
    academic_year_id = Attendance.fetch_academic_year(batch.id)
    unless elective_subjects.present?
      save_attendace = []
      elective_subjects = batch.elective_groups.each do |eg|
        save_attendace << MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id IN (?) ",academic_year_id,batch.id,'SubjectWise', eg.subjects.collect(&:id)])
      end
    else
      save_attendace = MarkedAttendanceRecord.all(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id =? and attendance_type = ? and subject_id IN (?) ",academic_year_id,batch.id,'SubjectWise', elective_subjects.collect(&:id)])
    end
    save_attendace = save_attendace.flatten.compact
    return save_attendace
  end
  
end
