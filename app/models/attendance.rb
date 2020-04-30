#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class Attendance < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch
  belongs_to :attendance_label

  #  attr_accessor :quick_mode
  attr_accessor :delay_notif, :attendance_save #, :attendance_submit
  validates_presence_of :month_date,:batch_id,:student_id
  validates_presence_of :attendance_label_id, :if => :validate_attendance_label
  validates_uniqueness_of :student_id, :scope => [:month_date] #,:message=> "#{t('already_marked')}"
  named_scope :by_month, lambda { |d| { :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month } } }
  named_scope :by_month_and_batch, lambda { |d,b| {:conditions  => { :month_date  => d.beginning_of_month..d.end_of_month,:batch_id=>b } } }
  named_scope :students_in_batches, lambda{|batch| {:conditions=>["student_id not in (?)",batch.batch_students.collect(&:student_id)]}}
  before_save :daily_wise_attendance_check , :check_custom_import_data
  after_create :verify_and_send_sms, :notify_student
  # after_create :update_attendance_status , :if => :attendace_lock
  after_save :update_attendance_status , :if => :attendace_lock
  before_save :check_attendance_status , :if => :attendace_lock
  include CsvExportMod

  def attendace_lock
    attendace_lock =  AttendanceSetting.is_attendance_lock
    if attendace_lock
      return true
    else
      return false
    end
  end

  def check_attendance_status
    batch_id = self.batch_id
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    month_date = self.month_date
    lock_attendance = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?)  and batch_id = ?  and attendance_type = ? and month_date =? and is_locked = ?",academic_year_id,batch_id,'Daily',month_date, true])
    if lock_attendance.present?
      errors.add_to_base("#{t('attendance_submitted')}")
      return false
    end
  end

  def update_attendance_status
    # user id will be nil via custom import saves
    today_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    batch_id = self.batch_id
    academic_year_id = Attendance.fetch_academic_year(batch_id)
    attendance_saved = self.attendance_save
    # attendance_submitted = self.attendance_submit
    month_date = self.month_date
    save_attendance(academic_year_id,month_date,today_date,batch_id)  if attendance_saved.present?
    # submit_attendance(academic_year_id,month_date,today_date,batch_id) if attendance_submitted.present?
  end

  def save_attendance(academic_year_id,month_date,today_date,batch_id)
    attendance = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ?  and attendance_type = ? and month_date =?",academic_year_id,batch_id,'Daily',month_date])
    unless attendance.present?
      MarkedAttendanceRecord.create(:academic_year_id => academic_year_id, :month_date => month_date,  :batch_id => batch_id,:attendance_type => 'Daily',:saved_by => nil, :saved_date => today_date)
    else
      attendance.update_attributes(:saved_by => nil,:saved_date => today_date)
    end
  end


  def submit_attendance(academic_year_id,month_date,today_date,batch_id)
    attendance = MarkedAttendanceRecord.first(:conditions => ["(academic_year_id is null or academic_year_id = ?) and batch_id = ? and month_date =? and attendance_type = ? ",academic_year_id,batch_id, month_date,'Daily'] )
    unless attendance.present?
      attendance = MarkedAttendanceRecord.create(:academic_year_id => academic_year_id, :month_date => month_date,  :batch_id => batch_id,:attendance_type => 'Daily',:saved_by => nil, :saved_date => today_date,:locked_by => nil, :locked_date => today_date, :is_locked => true)
    else
      attendance.update_attributes(:locked_date => today_date, :is_locked => true)
    end
  end

  def verify_and_send_sms
    custom_attendance_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    if custom_attendance_enable == '1'
      verify_and_send  if attendance_label_id.present? and attendance_label.has_notification == true
    else
      verify_and_send
    end
  end

  def verify_and_send
    sms_setting = SmsSetting.new()
    if sms_setting.delayed_sms_notification_active
      if (self.delay_notif.to_s == "true") or (self.delay_notif.nil?)
        self.update_attribute(:notification_sent, false)
        return
      else
        send_sms
      end
    else
      send_sms
    end
  end

  def reason_info
    if reason == ""
      return  'NA'
    else
      return reason
    end
  end

  def notify_student
    custom_attendance_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    user_ids = [student.user_id]
    user_ids << student.immediate_contact.user_id if student.immediate_contact.present?
    if  custom_attendance_enable == '1'
      if attendance_label_id.present? and attendance_label.has_notification == true
        body = t("attendance_notification_daily_wise",:student_full_name => student.full_name,
          :student_admission_no => student.admission_no, :attendance_label_name => attendance_label_name,
          :month_date => month_dates, :reason_info => reason_info,:leave_info_n => leave_info_n)
        inform(user_ids, body, 'Attendance')
      end
    else
      body = t("attendance_notification_daily_wise",:student_full_name => student.full_name,
        :student_admission_no => student.admission_no, :attendance_label_name => attendance_label_name,
        :month_date => month_dates, :reason_info => reason_info,:leave_info_n => leave_info_n)
      inform(user_ids, body, 'Attendance')
    end
  end

  def self.check_absentee(obj)
    unless obj.attendance_label_id == nil
      if  obj.present? and obj.attendance_label.attendance_type == 'Late'
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def validate_email_setting
    if attendance_label_id.present?
      if self.attendance_label.has_notification == true
        return true
      else
        return false
      end
    else
      return true
    end
  end

  def validate_attendance_label
    config = Configuration.get_config_value('CustomAttendanceType') || "0"
    if config == "1"
      return true
    else
      return false
    end
  end

  def self.attendance_type_check
    Configuration.find_by_config_key('StudentAttendanceType').config_value
  end

  def self.attendacne_type_status
    Configuration.find_by_config_key('CustomAttendanceType').config_value
  end

  def validate
    unless self.student.nil?
      if self.student.batch_id == self.batch_id
        if self.afternoon==false and self.forenoon==false
          errors.add_to_base :select_leave_session
        end
      else
        errors.add('batch_id',"attendance is not marked for present batch")
      end
      unless self.month_date.nil?
        errors.add :attendance_before_the_date_of_admission  if (self.month_date < self.student.admission_date and Configuration.is_batch_date_attendance_config? == false)
      else
        # errors.add :month_date_cant_be_blank #Already added in uniquness validation
      end
    end
    errors.add_to_base :cant_be_a_future_date if (month_date.present? and month_date > Configuration.default_time_zone_present_time.to_date)
  end

  def daily_wise_attendance_check
    config = Configuration.find_by_config_key('StudentAttendanceType')
    unless config.config_value=="SubjectWise"
      batch=self.batch
      working_days=batch.working_days(self.month_date.to_date)
      if working_days.include? self.month_date.to_date
        return true
      else
        errors.add_to_base :attendance_date_invalid
        return false
      end
    end
  end

  def check_custom_import_data
    config = Configuration.get_config_value('CustomAttendanceType') || "0"
    if config == "1"
      attendance_label = AttendanceLabel.find_by_attendance_type('Late')
      self.forenoon = self.afternoon = true if self.attendance_label_id == attendance_label.id
      return true
    else
      return true
    end
  end

  def is_full_day
    forenoon == true and afternoon == true
  end

  def is_half_day
    forenoon == true or afternoon == true
  end

  def month_dates
    format_date(month_date,:format=>:long)
  end

  def leave_info
    if forenoon and !afternoon
      return "#{t('forenoon')}"
    elsif afternoon and !forenoon
      "#{t('afternoon')}"
    end
  end

  def leave_info_n
    if forenoon and !afternoon
      return "#{t('for_forenoon')}"
    elsif afternoon and !forenoon
      "#{t('for_afternoon')}"
    end
  end

  def self.fetch_student_attendance_data(params)
    student_attendance_report params
  end

  def self.fetch_attendance_register_data(params)
    attendance_register_data(params)
  end

  def attendance_label_name
    if self.attendance_label_id.present?
      attendance_label = AttendanceLabel.find(self.attendance_label_id)
      if  attendance_label.attendance_type == "Late"
        return 'Late'
      else
        return 'Absent'
      end
    else
      return 'Absent'
    end
  end

  def self.name_mine
    AttendanceReport.my_name
  end
  def self.fetch_consolidated_subjectwise_attendance_data(params)
    consolidated_attendance_report params
  end

  def self.fetch_day_wise_report_data(params)
    day_wise_report params
  end

  def self.leave_calculation(start_date,end_date,students,batch,sub)
    attendance_lock = AttendanceSetting.is_attendance_lock
    subject_wise_leave = {}
    attendance_calc_settings = Configuration.get_config_value('AttendanceCalculation')||''
    sub.each do |subj|
      leaves = Hash.new
      #leaves = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      @academic_days = batch.subject_hours(start_date, end_date, subj.id) #- cancelled_subject_periods.count
      @academic_days_count = @academic_days.values.flatten.compact.count.to_i
      academic_days = 0
      report = SubjectLeave.find_all_by_subject_id(subj.id,  :conditions =>{:batch_id=>batch.id,:month_date => start_date..end_date})
      if attendance_lock
        normal_academic_days = MarkedAttendanceRecord.subject_wise_working_days(batch,subj.id).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
        elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(batch).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
        total_academic_days = normal_academic_days + elective_academic_days
        report = report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
      end
      grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
      students.each do |s|
        student_admission_date = s.admission_date
        academic_days_c = Hash.new
        if attendance_calc_settings.present?
          if attendance_calc_settings.to_s == 'StudentAdmissionDate'
            academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (@academic_days.each_pair {|x,y| academic_days_c[x] = y if x >= student_admission_date }; academic_days_c.values.flatten.count.to_i) : (start_date >= student_admission_date ? @academic_days_count : 0) #unless attendance_lock
          elsif attendance_calc_settings.to_s == 'BatchDate'
            academic_days = batch.subject_hours(start_date, end_date, subj.id).values.flatten.compact.count
          end
        else
          academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (@academic_days.each_pair {|x,y| academic_days_c[x] = y if x >= student_admission_date }; academic_days_c.values.flatten.count.to_i) : (start_date >= student_admission_date ? @academic_days_count : 0) #unless attendance_lock
        end
        leaves[s.id] = Hash.new
        is_elective = subj.elective_group_id
        if is_elective == nil
          if grouped[s.id].nil?
            leaves[s.id]['leave'] = 0
          else
            leaves[s.id]['leave'] = grouped[s.id].count
          end
          leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
          leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
        else
          if s.subjects.collect(&:id).include? subj.id
            if grouped[s.id].nil?
              leaves[s.id]['leave'] = 0
            else
              leaves[s.id]['leave'] = grouped[s.id].count
            end
            leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
            leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
          else
            leaves[s.id]['leave'] = '-'
            leaves[s.id]['total'] = '-'
            leaves[s.id]['percent'] = '-'
          end
        end
      end
      subject_wise_leave[subj.id] = leaves
      subject_wise_leave[subj.id]['academic_days'] = academic_days
    end
    return subject_wise_leave
  end

  def send_sms
    sms_setting = SmsSetting.new()
    student = self.student
    if sms_setting.application_sms_active and student.is_sms_enabled
      AutomatedMessageInitiator.dailywise_attendance(self) if Configuration.find_by_config_key('StudentAttendanceType').config_value== "Daily"
    else
      self.update_attribute(:notification_sent, false)
    end
  end

  #returns total leaves taken and total working days for a student for grade book
  def self.student_leaves_total(attendances,student,batch,start_date,end_date,holidays)
    attendance_lock = AttendanceSetting.is_attendance_lock
    if attendance_lock
      working_days = MarkedAttendanceRecord.dailywise_working_days(batch.id).select{|v| v <= end_date and  v >= start_date}
      leaves_forenoon, leaves_afternoon, leaves_full = attendance_record(attendances,batch,working_days,student)
    else
      total_weekday_sets = batch.attendance_weekday_sets.select{|obj| obj.start_date <= end_date and obj.end_date >= start_date}
      working_days = batch.date_range_working_days(start_date,end_date,total_weekday_sets,holidays)
      leaves_forenoon = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == true and obj.afternoon == false and obj.month_date >= start_date.to_date and obj.month_date <= end_date.to_date and obj.student_id == student.id }.count
      leaves_afternoon = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == false and obj.afternoon == true and obj.month_date >= start_date.to_date and obj.month_date <= end_date.to_date and obj.student_id == student.id }.count
      leaves_full = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == true and obj.afternoon == true and obj.month_date >= start_date.to_date and obj.month_date <= end_date.to_date and obj.student_id == student.id }.count
    end
    working_days_count = working_days.count
    student_admission_date = student.admission_date
    student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)
    leaves_total = leaves_full + 0.5*(leaves_afternoon+leaves_forenoon)

    return student_academic_days,leaves_total
  end

  # for grade book
  def self.attendance_record(attendances,batch,working_days,student)
    leaves_forenoon = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == true and obj.afternoon == false and working_days.include?(obj.month_date) and obj.student_id == student.id }.count
    leaves_afternoon = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == false and obj.afternoon == true and working_days.include?(obj.month_date) and obj.student_id == student.id }.count
    leaves_full = attendances.select{|obj| obj.batch_id == batch.id and obj.forenoon == true and obj.afternoon == true and working_days.include?(obj.month_date) and obj.student_id == student.id }.count
    return leaves_forenoon, leaves_afternoon, leaves_full
  end

  #return subject wise attendance for a student
  #only for grade book
  def self.calculate_subjectwise_attendance(student,batch,sub,start_date,end_date,holiday_event_dates)
    attendance_lock = AttendanceSetting.is_attendance_lock
    final_total = 0;final_academic_days = 0;final_percentage = 0;final_leave = 0;
    sub_leave ={}
    sub.each do |subj|
      leaves = Hash.new
      report = SubjectLeave.find_all_by_subject_id(subj.obj_id, :conditions =>{:batch_id=>batch.id,:month_date => start_date..end_date})
      unless attendance_lock
        academic_days = batch.subject_hours(start_date, end_date, subj.obj_id, nil, nil, holiday_event_dates).values.flatten.compact.count #- cancelled_subject_periods.count
      else
        academic_days = MarkedAttendanceRecord.subject_wise_working_days(batch,subj.obj_id).select{|v| v <= end_date and  v >= start_date}.count
        report = report.to_a.select{|a| academic_days.include?(a.month_date) }
      end
      report = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      grouped = report.group_by(&:student_id)
      if grouped[student.id].nil?
        leaves[:leave] = 0
      else
        final_leave+= grouped[student.id].count
        leaves[:leave] = grouped[student.id].count
      end
      leaves[:total] = (academic_days - leaves[:leave])
      leaves[:percent] = (leaves[:total].to_f/academic_days)*100 unless academic_days == 0
      sub_leave[subj.obj_id] = leaves
      sub_leave[subj.obj_id][:academic_days] = academic_days
      final_total+=  leaves[:total]
      final_academic_days+= academic_days
    end
    final_percentage = (final_total.to_f/final_academic_days)*100 unless final_academic_days == 0
    final={:total=>final_total,:academic_days=>final_academic_days,:leave=>final_leave,:percent=>final_percentage}
    sub_leave[:combined] = final
    return sub_leave
  end

  def self.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,academic_days_hash = nil)
    attendance_calc_settings = Configuration.get_config_value('AttendanceCalculation')||''
    unless academic_days_hash.nil?
      if attendance_calc_settings.present?
        if attendance_calc_settings.to_s == 'StudentAdmissionDate'
          student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (academic_days.each_pair {|x,y| academic_days_hash[x] = y if x >= student_admission_date }; academic_days_hash.values.flatten.count.to_i) : (start_date >= student_admission_date ? academic_days_count : 0)
        elsif attendance_calc_settings.to_s == 'BatchDate'
          student_academic_days = academic_days_count
        end
      else
        student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (academic_days.each_pair {|x,y| academic_days_hash[x] = y if x >= student_admission_date }; academic_days_hash.values.flatten.count.to_i) : (start_date >= student_admission_date ? academic_days_count : 0)
      end
    else
      if attendance_calc_settings.present?
        if attendance_calc_settings.to_s == 'StudentAdmissionDate'
          student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? academic_days.select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? academic_days_count : 0)
        elsif attendance_calc_settings.to_s == 'BatchDate'
          student_academic_days = academic_days_count
        end
      else
        student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? academic_days.select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? academic_days_count : 0)
      end
    end
    student_academic_days
  end

  #
  #  def self.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,academic_days_hash = nil)
  #    attendance_calc_settings = Configuration.get_config_value('AttendanceCalculation')||''
  #    attendance_lock_settings = AttendanceSetting.is_attendance_lock
  #    unless academic_days_hash.nil?
  #      unless attendance_lock_settings
  #        if attendance_calc_settings.present?
  #          if attendance_calc_settings.to_s == 'StudentAdmissionDate'
  #            student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (academic_days.each_pair {|x,y| academic_days_hash[x] = y if x >= student_admission_date }; academic_days_hash.values.flatten.count.to_i) : (start_date >= student_admission_date ? academic_days_count : 0)
  #          elsif attendance_calc_settings.to_s == 'BatchDate'
  #            student_academic_days = academic_days_count
  #          end
  #        else
  #          student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (academic_days.each_pair {|x,y| academic_days_hash[x] = y if x >= student_admission_date }; academic_days_hash.values.flatten.count.to_i) : (start_date >= student_admission_date ? academic_days_count : 0)
  #        end
  #      else
  #        student_academic_days = working_day_count(attendance_calc_settings,student_admission_date,end_date,start_date,academic_days,academic_days_count)
  #      end
  #    else
  #      student_academic_days = working_day_count(attendance_calc_settings,student_admission_date,end_date,start_date,academic_days,academic_days_count)
  #    end
  #    student_academic_days
  #  end
  #
  #  def self.working_day_count(attendance_calc_settings,student_admission_date,end_date,start_date,academic_days,academic_days_count)
  #    if attendance_calc_settings.present?
  #      if attendance_calc_settings.to_s == 'StudentAdmissionDate'
  #        student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? academic_days.select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? academic_days_count : 0)
  #      elsif attendance_calc_settings.to_s == 'BatchDate'
  #        student_academic_days = academic_days_count
  #      end
  #    else
  #      student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? academic_days.select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? academic_days_count : 0)
  #    end
  #    return student_academic_days
  #  end


  def self.calculate_student_working_days_elective(student_admission_date,end_date,start_date,elect_days,elective_academic_days,se)
    attendance_calc_settings = Configuration.get_config_value('AttendanceCalculation')||''
    attendance_lock_settings = AttendanceSetting.is_attendance_lock
    if attendance_calc_settings.present?
      if attendance_calc_settings.to_s == 'StudentAdmissionDate'
        student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? elect_days[se].select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? elect_days[se].count : 0) if attendance_lock_settings
        student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (elect_days[se].each_pair {|x,y| elective_academic_days[x] = y if x >= student_admission_date }; elective_academic_days.values.flatten.compact.count.to_i) : (start_date >= student_admission_date ? elect_days[se].values.flatten.compact.count.to_i : 0) unless attendance_lock_settings
      elsif attendance_calc_settings.to_s == 'BatchDate'
        student_academic_days = elect_days[se].count.to_i if attendance_lock_settings
        student_academic_days = elect_days[se].values.flatten.compact.count.to_i unless attendance_lock_settings
      end
    else
      student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? elect_days[se].select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? elect_days[se].count : 0) if attendance_lock_settings
      student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (elect_days[se].each_pair {|x,y| elective_academic_days[x] = y if x >= student_admission_date }; elective_academic_days.values.flatten.compact.count.to_i) : (start_date >= student_admission_date ? elect_days[se].values.flatten.compact.count.to_i : 0) unless attendance_lock_settings
    end
    student_academic_days
  end

  def self.get_absent(student_id, date_val, batch)
    absent = Attendance.find_by_student_id_and_month_date_and_batch_id(student_id , date_val, batch)
    return absent
  end

  def self.fetch_absent_count(dates,students, subject_id = nil)
    absentes = {}
    attendance_label_id = AttendanceLabel.find_by_attendance_type('Absent').try(:id)
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    dates.each do |date|
      if attendance_type == 'Daily'
        absent = Attendance.all(:conditions => ["student_id IN (?) and month_date = ? and (attendance_label_id is null or attendance_label_id = ?)",students.collect(&:id), date, attendance_label_id ])
        absent_per_day = absent.present? ? absent.count : 0
        absentes[date] =  absent_per_day
      elsif attendance_type == 'SubjectWise' and subject_id.present?
        absents = SubjectLeave.all(:conditions => ["(student_id IN (?) and month_date = ?) and (attendance_label_id is null or attendance_label_id = ?) and subject_id = ?",students.collect(&:id), date[0], attendance_label_id, subject_id ]).group_by(&:class_timing_id)
        absentes[date[0]] = {}
        absents.each do |ct, absent|
          absent_per_day = absent.present? ? absent.count : 0
          absentes[date[0]][ct] =  absent_per_day
        end
      end
    end
    return absentes
  end

  def self.fetch_late_count(dates,students, subject_id = nil)
    absentees = {}
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    attendance_label_id = AttendanceLabel.find_by_attendance_type('Late').try(:id)
    dates.each do |date|
      if attendance_type == 'Daily'
        absent = Attendance.all(:conditions => ["student_id IN (?) and month_date = ? and attendance_label_id = ? ",students.collect(&:id), date, attendance_label_id])
        absent_per_day = absent.present? ? absent.count : 0
        absentees[date] =  absent_per_day
      elsif attendance_type == 'SubjectWise' and subject_id.present?
        absents = SubjectLeave.all(:conditions => ["student_id IN (?) and month_date = ? and attendance_label_id = ?  and subject_id = ?",students.collect(&:id), date[0], attendance_label_id, subject_id ]).group_by(&:class_timing_id)
        absentees[date[0]] = {}
        absents.each do |ct, absent|
          absent_per_day = absent.present? ? absent.count : 0
          absentees[date[0]][ct] =  absent_per_day
        end
      end
    end
    return absentees
  end


  def self.academic_year(batch)
    academic_year = batch.academic_year
    academic_year_id = academic_year.present? ? academic_year.id : nil
    return academic_year_id
  end

  def self.fetch_academic_year(batch_id)
    batch = Batch.find(batch_id)
    academic_year = batch.academic_year
    academic_year_id = academic_year.present? ? academic_year.id : nil
    return academic_year_id
  end

  def self.dailywise_attendance_data(student,batch_id,month_date,end_date,academic_days)
    attendance_label_id = AttendanceLabel.find_by_attendance_type('Absent').try(:id)
    student_attendance = Attendance.find(:all,:select => "(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and
                   attendances.batch_id=#{batch_id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND
                   '#{end_date}' and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and
                   attendances.batch_id=#{batch_id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))+
                   count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id} and
                   `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}'and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL))))) as leaves,
                   (#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and
                    attendances.batch_id=#{batch_id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}'and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-
                    (0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id} and
                    `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}'and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and
                   attendances.forenoon=0 and attendances.batch_id=#{batch_id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND
                 '#{end_date}'and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL)))))/#{academic_days}*100 as percent",
      :conditions => {:batch_id => batch_id,:student_id=>student.id_in_context}).first
    return student_attendance
  end

  def self.dailywise_save_attendance_data(student,batch_id,academic_days)
    full_leaves = Attendance.all(:conditions =>["batch_id= ? and student_id =? and forenoon= ? and afternoon= ? and month_date IN (?)",batch_id,student,true,true,academic_days])
    leaves_forenoon = Attendance.all(:conditions=>["batch_id= ? and student_id =? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch_id,student.id,true,false,academic_days])
    leaves_afternoon = Attendance.all(:conditions=>["batch_id= ? and student_id =? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch_id,student.id,false,true,academic_days])
    leaves_forenoon = leaves_forenoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_afternoon = leaves_afternoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    full_leaves = full_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    total_leaves = full_leaves.to_f + (0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f))
    academic_days_count = (academic_days.count).to_f
    percent = academic_days.present? ? ((academic_days_count - total_leaves.to_f)/academic_days_count)*100 : 0
    persent_days = academic_days.present? ? (academic_days_count - total_leaves).to_f : 0
    return {"percent"=>percent,"leaves"=>persent_days,"academic_days"=>academic_days_count}
  end

  def self.student_working_day(student_admission_date,month_date)
    attendance_calc_settings = Configuration.get_config_value('AttendanceCalculation')||''
    if attendance_calc_settings.present?
      if attendance_calc_settings.to_s == 'StudentAdmissionDate' 
        month_date =  (month_date < student_admission_date) ? student_admission_date : month_date
      elsif attendance_calc_settings.to_s == 'BatchDate'
        month_date = month_date
      end
    else
      month_date =  (month_date < student_admission_date) ? student_admission_date : month_date
    end
    return month_date
  end
  
  def self.dailywise_attendance_status(batch_id,dates)
    enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    attendance_status = {}
    attendance_status['marked'] = []
    dates.each do |date|
      attendance = Attendance.find(:all,:conditions => ["batch_id = ? and month_date = ?", batch_id,date])
      attendance=  attendance.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"} if (enable == '0')
      attendance_status['marked'] << date  if attendance.present? 
    end
    return attendance_status
  end
   
end

