# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class DelayedSaveStudentAttendance

  def initialize(current_user)
    @current_user = current_user
  end

  def perform
    errors = []
    batches = Batch.active
    ActiveRecord::Base.transaction do
      attendance_lock = AttendanceSetting.is_attendance_lock
      if attendance_lock
        batches.each do |batch|
          errors = save_attandance_record(batch,errors)
        end
        configuration_data_update() unless errors.present?
      end
    end
  end

  def save_attandance_record(batch,errors)
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    current_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    if attendance_type == 'Daily'
      save_data_config = Configuration.get_config_value('DailyWiseAttendanceLockData')
      errors = dailywise_attendance_record(batch,attendance_type,current_date,errors) unless save_data_config == '1'
    elsif attendance_type == 'SubjectWise'
      save_data_config = Configuration.get_config_value('SubjectWiseAttendanceLockData')
      errors = subjectwise_attendance_record(batch,attendance_type,current_date,errors) unless save_data_config == '1'
    end
    return errors
  end

  def dailywise_attendance_record(batch, attendance_type,current_date,errors)
    academic_year_id = Attendance.academic_year(batch)
    working_days = batch.academic_days
    working_days.each do |working_day|
      e = MarkedAttendanceRecord.new(:batch_id => batch.id,:attendance_type => attendance_type, :month_date => working_day,
        :saved_date => current_date, :saved_by => @current_user.id, :locked_date => current_date, :locked_by => @current_user.id ,
        :academic_year_id => academic_year_id, :is_locked => true)
      errors << e.errors.full_messages unless e.save
    end
    return errors
  end

  def subjectwise_attendance_record(batch,attendance_type,current_date,errors)
    academic_year_id = Attendance.academic_year(batch)
    start_date = batch.start_date.to_date
    end_date = current_date
    working_days = batch.subject_hours(start_date, end_date, 0, nil, "normal")
    working_days.each do |date,academic_days|
      academic_days.each do |academic_day|
        if academic_day.entry_type == "Subject"
          e = MarkedAttendanceRecord.new(:batch_id => batch.id,:attendance_type => attendance_type, :month_date => date, :saved_date => current_date,
            :saved_by => @current_user.id, :locked_date => current_date, :locked_by => @current_user.id ,:academic_year_id => academic_year_id,
            :is_locked => true,:class_timing_id => academic_day.class_timing_id,:subject_id => academic_day.entry_id)
          errors << e.errors.full_messages unless e.save
        end
      end
    end
    elective_groups = batch.elective_groups.active
    elective_groups.each do |es|
      working_days =  batch.subject_hours(start_date, end_date, es.id, nil, "elective")
      working_days.each do |date,academic_days|
        academic_days.each do |academic_day|
          if academic_day.entry_type == "ElectiveGroup"
            elective_group = ElectiveGroup.find(academic_day.entry_id)
            elective_group_subjects = elective_group.subjects.active
            elective_group_subjects.each do |subject|
              e = MarkedAttendanceRecord.new(:batch_id => batch.id,:attendance_type => attendance_type, :month_date => date, :saved_date => current_date,
                :saved_by => @current_user.id, :locked_date => current_date, :locked_by => @current_user.id ,:academic_year_id => academic_year_id,
                :is_locked => true,:class_timing_id => academic_day.class_timing_id,:subject_id => subject.id)
              errors << e.errors.full_messages unless e.save
            end
          end
        end
      end
    end
    return errors
  end

  def configuration_data_update()
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    if attendance_type == "Daily"
      Configuration.set_value("DailyWiseAttendanceLockData", '1')
    elsif attendance_type == "SubjectWise"
      Configuration.set_value("SubjectWiseAttendanceLockData", '1')
    end
  end

end
