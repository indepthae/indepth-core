class Api::AttendancesController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendances = Attendance.search(params[:search]).all
    else
      @attendances = SubjectLeave.search(params[:search]).all
    end
    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :attendances }
      end
    end

  end

  def new
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:admission_no]])
      @month_date = params[:date]
      @attendance = Attendance.new
      @attendance.month_date = @month_date
    else
      @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:admission_no]])
      @attendance = SubjectLeave.new
    end
    
    respond_to do |format|
      format.xml  { render :xml => @attendance }
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:admission_no]])
    config = Configuration.find_by_config_key('StudentAttendanceType')
    config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    academic_year_id = AcademicYear.fetch_academic_year_id
    attendance_lock = AttendanceSetting.is_attendance_lock
    if config.config_value=="SubjectWise"
      @attendance = SubjectLeave.new
      if student.present?
        subject_id = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
        class_timings = ClassTiming.find_all_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name])
        class_timings = ClassTiming.find_all_by_batch_id_and_name(nil,params[:class_timing_name]) unless class_timings.present?
        timetable_entry = Timetable.tte_for_the_day(student.try(:batch),params[:date].to_date).select{|s| class_timings.map{|ct| ct.id}.include?(s.class_timing_id) && s.subject_id==subject_id}.first if params[:date].present?
        if attendance_lock
          locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and month_date = ? and subject_id = ? and class_timing_id = ? and attendance_type = ? and is_locked = ?", academic_year_id, student.try(:batch_id),params[:date].to_date,subject_id,timetable_entry.class_timing_id, 'SubjectWise', true])
          @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
        end
        if timetable_entry.present?
          @attendance.subject_id = subject_id
          @attendance.employee_id =timetable_entry.try(:employee_id)
          @attendance.class_timing_id = timetable_entry.class_timing_id
        else
          @attendance.errors.add_to_base("Timetable entry not found")
        end
      else
        @attendance.errors.add_to_base("Student not found")
      end
    else
      @attendance = Attendance.new
      if student.present?
        @attendance.forenoon = params[:forenoon]
        @attendance.afternoon = params[:afternoon]
        if attendance_lock
          locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and attendance_type = ? and month_date = ? and is_locked = ?", academic_year_id, student.try(:batch_id), 'Daily', params[:date].to_date,true])
          @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
        end
      else
        @attendance.errors.add_to_base("Student not found")
      end
    end
    @attendance.student_id = student.try(:id)
    @attendance.batch_id = student.try(:batch_id)
    @attendance.month_date = params[:date].to_date
    @attendance.reason = params[:reason]
    if config_enable == '1' and params[:attendance_label_name].present?  
      attendance_label_id = AttendanceLabel.find_by_name(params[:attendance_label_name]).try(:id)
      @attendance.attendance_label_id = attendance_label_id
    end
    respond_to do |format|
      if @attendance.save
        flash[:notice] = 'Attendance was successfully created.'
        format.xml  { render :attendance, :status => :created }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @xml = Builder::XmlMarkup.new
    student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
    end
    respond_to do |format|
      format.xml  { render :attendance }
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    academic_year_id = AcademicYear.fetch_academic_year_id
    attendance_lock = AttendanceSetting.is_attendance_lock
    student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @config_enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
      if attendance_lock
        locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and attendance_type = ? and month_date = ? and is_locked = ?", academic_year_id, student.try(:batch_id), 'Daily',params[:date], true])
        @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
      end
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      class_timing ||= ClassTiming.find_by_batch_id_and_name(nil,params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
      if attendance_lock
        locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and subject_id = ? and class_timing_id = ? and attendance_type = ? and month_date = ? and is_locked = ?", academic_year_id, student.try(:batch_id),subject,class_timing, 'SubjectWise',params[:date], true])
        @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
      end
    end

    respond_to do |format|
      if @config_enable == '1' and  params[:attendance_label_name].present?
        attendance_label_id = AttendanceLabel.find_by_name(params[:attendance_label_name]).try(:id)
        @attendance.attendance_label_id = attendance_label_id  
      end
      if @config.config_value=='Daily'
        @attendance.forenoon = params[:forenoon]
        @attendance.afternoon = params[:afternoon]
      end
      if !@attendance.errors.present? and @attendance.update_attributes(:reason => params[:reason])
        flash[:notice] = 'Post was successfully updated.'
        format.xml  { render :attendance }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity } 
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date].to_date,student.try(:batch_id),class_timing)
    end

    respond_to do |format|
      format.xml  { render :attendance }
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    academic_year_id = AcademicYear.fetch_academic_year_id
    attendance_lock = AttendanceSetting.is_attendance_lock
    student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
      if attendance_lock
        locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and attendance_type = ? and month_date = ? and is_locked = ?", academic_year_id, student.try(:batch_id), 'Daily', params[:date],true])
        @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
      end
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(nil,params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
      if attendance_lock
        locked_attendance = MarkedAttendanceRecord.first(:conditions => ["academic_year_id = ? and batch_id =? and subject_id = ? and class_timing_id = ? and attendance_type = ? and month_date = ? and is_locked = ?", academic_year_id, student.try(:batch_id),subject,class_timing, 'SubjectWise', params[:date],true])
        @attendance.errors.add_to_base("Attendance has been submitted for the day")  if locked_attendance.present?
      end
    end
    respond_to do |format|
      unless @attendance.errors.present?
        @attendance.destroy
        format.xml  { render :delete }
      else
        format.xml   { render :xml => @attendance.errors, :status => :unprocessable_entity } 
      end
    end
  end
  
end
