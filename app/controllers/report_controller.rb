require 'fee_collection_report'
class ReportController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  filter_access_to [:siblings_report,:siblings_report_csv,:siblings_course_select,:former_employees,:former_employees_csv,:employee_subject_association,:employee_subject_association_csv,:employee_payroll_details,:employee_payroll_details_csv], :attribute_check=>true, :load_method=>lambda{current_user}
  #  filter_access_to [:former_employees,:former_employees_csv,:employee_subject_association,:employee_subject_association_csv,:employee_payroll_details,:employee_payroll_details_csv], :attribute_check=>true
  #  filter_access_to [:employee_subject_association,:employee_subject_association_csv], :attribute_check=>true
  #  filter_access_to [:employee_payroll_details,:employee_payroll_details_csv], :attribute_check=>true
  include LinkPrivilege
  helper_method('link_to', 'link_to_remote', 'link_present')
  include FeeDefaultersSqlGenerator
  check_request_fingerprint :course_batch_details_csv, :batch_details_csv, :course_batch_details_csv, :batch_details_all_csv, :batch_students_csv,
    :course_students_csv, :students_all_csv, :employees_csv, :former_students_csv, :former_employees_csv, :subject_details_csv, :employee_payroll_details_csv,
    :exam_schedule_details_csv, :course_fee_defaulters_csv, :course_fee_defaulters_csv, :batch_fee_defaulters_csv, :employee_subject_association_csv,
    :fee_collection_details_csv, :batch_head_wise_fees_csv, :fee_collection_head_wise_report_csv,:siblings_report_csv, :student_wise_fee_defaulters_csv

  def index
    @course_count=Course.active.count
    @batch_count=Batch.active.count
    @student_count=Student.count
    @employee_count=Employee.count
  end

  def csv_reports

    if (MultiSchool rescue false)
      @jobs=Delayed::Job.all(:conditions=> ["queue in (?)", ['additional_reports', 'transport']]).select { |j| j.payload_object.class.name=="DelayedAdditionalReportCsv" and MultiSchool.current_school.id== (j.payload_object.instance_variable_get(:@school_id) || (j.payload_object.respond_to?(:school_id) && j.payload_object.school_id))}
    else
      @jobs=Delayed::Job.all(:conditions=> ["queue in (?)", ['additional_reports', 'transport']]).select { |j| j.payload_object.class.name=="DelayedAdditionalReportCsv" }
    end
    @csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(params[:model], params[:method])
  end

  def csv_report_download
    upload = AdditionalReportCsv.find(params[:id])
    send_file upload.csv_report.path,
      :filename => upload.csv_report_file_name,
      :type => upload.csv_report_content_type,
      :disposition => 'csv_report'
  end

  def course_batch_details
    @sort_order=params[:sort_order]
    unless @sort_order.nil?
      @courses=Course.paginate(:select => "courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count", :conditions => {:courses => {:is_deleted => false}}, :joins => "left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id", :group => "courses.id", :page => params[:page], :per_page => 20, :order => @sort_order)
    else
      @courses=Course.paginate(:select => "courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count", :conditions => {:courses => {:is_deleted => false}}, :joins => "left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id", :group => "courses.id", :page => params[:page], :per_page => 20, :order => 'course_name ASC')
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "all_courses_details"
      end
    end
  end

  def course_batch_details_csv
    parameters={:sort_order => params[:sort_order]}
    csv_export('course', 'course_details', parameters)
  end

  def donation_list_csv
    parameters=params[:donors_list]
    if parameters.nil?
      parameters={:from => 1.month.ago.beginning_of_day, :to => Date.today.end_of_day}
    end
    csv_export('finance_donation', 'donors_list', parameters)
  end

  def batch_details
    @course=Course.find params[:id]
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @batches=Batch.all(:select => 'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender like "%m%",1,NULL)) as male_count ,count(IF(students.gender like "%f%",1,NULL)) as female_count', :joins => "left outer join students on batches.id=students.batch_id", :conditions => {:course_id => params[:id], :is_active => true, :is_deleted => false}, :group => 'batches.id', :order => 'start_date ASC')
    else
      @batches=Batch.all(:select => 'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender like "%m%",1,NULL)) as male_count ,count(IF(students.gender like "%f%",1,NULL)) as female_count', :joins => "left outer join students on batches.id=students.batch_id", :conditions => {:course_id => params[:id], :is_active => true, :is_deleted => false}, :group => 'batches.id', :order => @sort_order)
    end
    @employees=Employee.all(:select => 'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number', :conditions => {:batches => {:course_id => params[:id]}}, :joins => [:batches]).group_by(&:batch_id)
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "individual_batch_details"
      end
    end
  end

  def batch_details_csv
    course=Course.find params[:id]
    sort_order=params[:sort_order]
    if sort_order.nil?
      batches=Batch.all(:select => 'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender="m",1,NULL)) as male_count ,count(IF(students.gender="f",1,NULL)) as female_count', :joins => "left outer join students on batches.id=students.batch_id", :conditions => {:course_id => params[:id], :is_active => true, :is_deleted => false}, :group => 'batches.id', :order => 'name ASC')
    else
      batches=Batch.all(:select => 'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender="m",1,NULL)) as male_count ,count(IF(students.gender="f",1,NULL)) as female_count', :joins => "left outer join students on batches.id=students.batch_id", :conditions => {:course_id => params[:id], :is_active => true, :is_deleted => false}, :group => 'batches.id', :order => sort_order)
    end
    employees=Employee.all(:select => 'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number', :conditions => {:batches => {:course_id => params[:id]}}, :joins => [:batches]).group_by(&:batch_id)

    csv_string=FasterCSV.generate do |csv|
      cols=["#{t('no_text')}", "#{t('name')}", "#{t('start_date')}", "#{t('end_date')}", "#{t('tutor')}", "#{t('students')}", "#{t('male')}", "#{t('female')}"]
      csv << cols
      batches.each_with_index do |b, i|
        col=[]
        col<< "#{i+1}"
        col<< "#{b.name}"
        col<< "#{format_date(b.start_date.to_date)}"
        col<< "#{format_date(b.end_date.to_date)}"
        unless employees.blank?
          unless employees[b.id.to_s].nil?
            emp=[]
            employees[b.id.to_s].each do |em|
              emp << "#{em.full_name} ( #{em.employee_number} )"
            end
            col << "#{emp.join("\n")}"
          else
            col << "--"
          end
        else
          col << "--"
        end
        col<< "#{b.student_count}"
        col<< "#{b.male_count}"
        col<< "#{b.female_count}"
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{course.course_name} #{t('batch')}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def batch_details_all
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @batches=Batch.paginate(:select => "batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count", :joins => "LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'batches.id', :conditions => {:is_deleted => false, :is_active => true}, :include => :course, :per_page => 20, :page => params[:page], :order => 'code ASC')
    else
      @batches=Batch.paginate(:select => "batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count", :joins => "LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'batches.id', :conditions => {:is_deleted => false, :is_active => true}, :include => :course, :per_page => 20, :page => params[:page], :order => @sort_order)
    end
    batch_ids=@batches.collect(&:id)
    @employees=Employee.all(:select => 'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number', :joins => [:batches], :conditions => {:batches => {:id => batch_ids}}).group_by(&:batch_id)
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_details_report"
      end
    end
  end

  def batch_details_all_csv
    parameters={:sort_order => params[:sort_order]}
    csv_export('batch', 'batch_details', parameters)
  end

  def batch_students
    @attendance_lock = AttendanceSetting.is_attendance_lock
    @batch=Batch.find params[:id]
    month_date=@batch.start_date.to_date
    end_date=Time.now.to_date
    config=Configuration.find_by_config_key('StudentAttendanceType')
    b_id=params[:id]
    @sort_order=params[:sort_order]
    attendance_label_id = AttendanceLabel.find_by_attendance_type('Absent').try(:id)
    attendance_label_id = attendance_label_id.present? ? attendance_label_id : 0
    unless config.config_value == 'Daily'
        academic_days=@batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
      unless params[:gender].present?
        if @sort_order.nil?
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id}  and (subject_leaves.attendance_label_id is null or subject_leaves.attendance_label_id = #{attendance_label_id}),subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => params[:id]}, :per_page => 20, :page => params[:page], :order => 'first_name ASC')
        else
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id}  and (subject_leaves.attendance_label_id is null or subject_leaves.attendance_label_id = #{attendance_label_id}),subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => params[:id]}, :per_page => 20, :page => params[:page], :order => @sort_order)
        end
      else
        if @sort_order.nil?
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id} and (subject_leaves.attendance_label_id is null or subject_leaves.attendance_label_id = #{attendance_label_id}),subject_leaves.id,NULL)))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE?", b_id, params[:gender]], :per_page => 20, :page => params[:page], :order => 'first_name ASC')
        else
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id} and (subject_leaves.attendance_label_id is null or subject_leaves.attendance_label_id = #{attendance_label_id}),subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE?", b_id, params[:gender]], :per_page => 20, :page => params[:page], :order => @sort_order)
        end
      end
    else
        academic_days=@batch.academic_days.count
      unless params[:gender].present?
        if @sort_order.nil?
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id}  and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => params[:id]}, :per_page => 20, :page => params[:page], :order => 'first_name ASC')
        else
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id}  and (attendances.attendance_label_id is null or attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => params[:id]}, :per_page => 20, :page => params[:page], :order => @sort_order)
        end
      else
        if @sort_order.nil?
          @students= Student.paginate(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id}  and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE ?", params[:id], params[:gender]], :per_page => 20, :page => params[:page], :order => 'first_name ASC')
        else
          @students= Student.paginate(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id}  and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id} and (attendances.attendance_label_id is null or attendances.attendance_label_id = #{attendance_label_id}),attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE ?", params[:id], params[:gender]], :per_page => 20, :page => params[:page], :order => @sort_order)
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_students_details"
      end
    end
  end

  def batch_students_csv
    parameters={:sort_order => params[:sort_order], :batch_id => params[:id], :gender => params[:gender]}
    csv_export('student', 'batch_wise_students', parameters)
  end

  def course_students
    @course=Course.find params[:id]
    @sort_order=params[:sort_order]
    unless params[:gender].present?
      if @sort_order.nil?
        @students= Student.paginate(:select => "students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => {:courses => {:id => params[:id]}}, :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @students= Student.paginate(:select => "students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => {:courses => {:id => params[:id]}}, :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    else
      if @sort_order.nil?
        @students= Student.paginate(:select => "students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => ["courses.id=? AND students.gender LIKE ?", params[:id], params[:gender]], :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @students= Student.paginate(:select => "students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => ["courses.id=? AND students.gender LIKE ?", params[:id], params[:gender]], :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "course_students_details"
      end
    end
  end

  def course_students_csv
    parameters={:sort_order => params[:sort_order], :course_id => params[:id], :gender => params[:gender]}
    csv_export('student', 'course_wise_students', parameters)
  end

  def students_all
    @sort_order=params[:sort_order]
    if params[:subject_id].nil?
      @count=Student.all(:select => "count(IF(students.gender Like '%m%' ,1,NULL)) as male_count, count(IF(students.gender LIKE '%f%',1,NULL)) as female_count")
      if @sort_order.nil?
        @students= Student.paginate(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @students= Student.paginate(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    else
      @count=Student.all(:select => "count(IF(students.gender Like '%m%' ,1,NULL)) as male_count, count(IF(students.gender LIKE '%f%',1,NULL)) as female_count", :joins => [:students_subjects], :conditions => ["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id", params[:subject_id]])
      if @sort_order.nil?
        @students= Student.paginate(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id", :group => 'students.id', :conditions => ["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id", params[:subject_id]], :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @students= Student.paginate(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id", :group => 'students.id', :conditions => ["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id", params[:subject_id]], :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "students_all_details"
      end
    end
  end

  def students_all_csv
    parameters={:sort_order => params[:sort_order], :subject_id => params[:subject_id]}
    csv_export('student', 'students_details', parameters)
  end

  def employees
    @dpt_count=EmployeeDepartment.active.count
    @count=Employee.all(:select => "count(IF(employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(employees.gender LIKE '%f%',1,NULL)) as female_count")
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @employees=Employee.paginate(:select => "employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id", :per_page => 20, :page => params[:page], :order => 'first_name ASC')
    else
      @employees=Employee.paginate(:select => "employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id", :per_page => 20, :page => params[:page], :order => @sort_order)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "employees_list"
      end
    end
  end

  def employees_csv
    parameters={:sort_order => params[:sort_order]}
    csv_export('employee', 'employee_details', parameters)
  end

  def former_students
    @sort_order=params[:sort_order]
    unless params[:former_students].nil?
      @count=ArchivedStudent.all(:select => "count(IF(archived_students.gender like '%m%',1,NULL)) as male_count,count(IF(archived_students.gender LIKE '%f%',1,NULL))as female_count", :conditions => {:archived_students => {:date_of_leaving => params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}})
      if @sort_order.nil?
        @students=ArchivedStudent.paginate(:select => "first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.date_of_leaving,archived_students.created_at", :joins => [:batch => :course], :conditions => {:archived_students => {:date_of_leaving => params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}}, :page => params[:page], :per_page => 20, :order => 'first_name ASC')
      else
        @students=ArchivedStudent.paginate(:select => "first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.date_of_leaving,archived_students.created_at", :joins => [:batch => :course], :conditions => {:archived_students => {:date_of_leaving => params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}}, :page => params[:page], :per_page => 20, :order => @sort_order)
      end
    else
      @count=ArchivedStudent.all(:select => "count(IF(archived_students.gender like '%m%',1,NULL)) as male_count,count(IF(archived_students.gender LIKE '%f%',1,NULL))as female_count", :conditions => {:archived_students => {:created_at => Date.today.beginning_of_day..Date.today.end_of_day}})
      if @sort_order.nil?
        @students=ArchivedStudent.paginate(:select => "first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving", :joins => [:batch => :course], :conditions => {:archived_students => {:date_of_leaving => Date.today.beginning_of_day..Date.today.end_of_day}}, :page => params[:page], :per_page => 20, :order => 'first_name ASC')
      else
        @students=ArchivedStudent.paginate(:select => "first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving", :joins => [:batch => :course], :conditions => {:archived_students => {:date_of_leaving => Date.today.beginning_of_day..Date.today.end_of_day}}, :page => params[:page], :per_page => 20, :order => @sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "former_students_details"
      end
    end
  end

  def former_students_csv
    parameters={:sort_order => params[:sort_order], :former_students => params[:former_students]}
    csv_export('archived_student', 'former_students_details', parameters)
  end

  def former_employees
    @sort_order=params[:sort_order]
    unless params[:former_employee].nil?
      @count=ArchivedEmployee.all(:select => "count(IF(archived_employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(archived_employees.gender LIKE '%f%',1,NULL)) as female_count,archived_employees.date_of_leaving", :conditions => {:archived_employees => {:date_of_leaving => params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}})
      if @sort_order.nil?
        @former_employees=ArchivedEmployee.paginate(:select => "archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id", :conditions => {:archived_employees => {:date_of_leaving => params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}}, :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @former_employees=ArchivedEmployee.paginate(:select => "archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id", :conditions => {:archived_employees => {:date_of_leaving => params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}}, :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    else
      @count=ArchivedEmployee.all(:select => "count(IF(archived_employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(archived_employees.gender LIKE '%f%',1,NULL)) as female_count", :conditions => {:archived_employees => {:date_of_leaving => Date.today.beginning_of_day..Date.today.end_of_day}})
      if @sort_order.nil?
        @former_employees=ArchivedEmployee.paginate(:select => "archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id", :conditions => {:archived_employees => {:date_of_leaving => Date.today.beginning_of_day..Date.today.end_of_day}}, :per_page => 20, :page => params[:page], :order => 'first_name ASC')
      else
        @former_employees=ArchivedEmployee.paginate(:select => "archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.date_of_leaving", :joins => "INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id", :conditions => {:archived_employees => {:date_of_leaving => Date.today.beginning_of_day..Date.today.end_of_day}}, :per_page => 20, :page => params[:page], :order => @sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "former_employees_list"
      end
    end
  end

  def former_employees_csv
    parameters={:sort_order => params[:sort_order], :former_employee => params[:former_employee]}
    csv_export('archived_employee', 'former_employees_details', parameters)
  end

  def subject_details
    @courses=Course.all(:select => "course_name,section_name,id", :conditions => {:is_deleted => false}, :order => 'course_name ASC')
    @sort_order=params[:sort_order]
    if params[:subject_search].nil?
      if @sort_order.nil?
        @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => 'name ASC')
      else
        @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => @sort_order)
      end
    else
      if @sort_order.nil?
        if params[:subject_search][:elective_subject]=="1" and params[:subject_search][:normal_subject]=="0"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code", :joins => "INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'subjects.id', :conditions => ["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?", params[:subject_search][:batch_ids], "", false], :page => params[:page], :per_page => 20, :order => 'name ASC')
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code", :joins => "INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'subjects.id', :conditions => ["elective_group_id != ? and subjects.is_deleted=? and batches.is_active=? and batches.is_deleted=?", "", false, true, false], :page => params[:page], :per_page => 20, :order => 'name ASC')
          end
        elsif params[:subject_search][:elective_subject]=="0" and params[:subject_search][:normal_subject]=="1"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:id => params[:subject_search][:batch_ids]}, :elective_group_id => nil}, :page => params[:page], :per_page => 20, :order => 'name ASC')
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :elective_group_id => nil, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => 'name ASC')
          end
        else
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:id => params[:subject_search][:batch_ids]}}, :page => params[:page], :per_page => 20, :order => 'name ASC')
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => 'name ASC')
          end
        end
      else
        if params[:subject_search][:elective_subject]=="1" and params[:subject_search][:normal_subject]=="0"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code", :joins => "INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'subjects.id', :conditions => ["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?", params[:subject_search][:batch_ids], "", false], :page => params[:page], :per_page => 20, :order => @sort_order)
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code", :joins => "INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :group => 'subjects.id', :conditions => ["elective_group_id != ? and subjects.is_deleted=? and batches.is_active=? and batches.is_deleted=?", "", false, true, false], :page => params[:page], :per_page => 20, :order => @sort_order)
          end
        elsif params[:subject_search][:elective_subject]=="0" and params[:subject_search][:normal_subject]=="1"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:id => params[:subject_search][:batch_ids]}, :elective_group_id => nil}, :page => params[:page], :per_page => 20, :order => @sort_order)
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :elective_group_id => nil, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => @sort_order)
          end
        else
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:id => params[:subject_search][:batch_ids]}}, :page => params[:page], :per_page => 20, :order => @sort_order)
          else
            @subjects=Subject.paginate(:select => "batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code", :joins => [:batch => :course], :conditions => {:is_deleted => false, :batches => {:is_deleted => false, :is_active => true}}, :page => params[:page], :per_page => 20, :order => @sort_order)
          end
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "subject_list"
      end
    end
  end

  def list_batches
    unless params[:course_id].blank?
      @batches=Batch.all(:select => "name,id,course_id", :conditions => {:course_id => params[:course_id], :is_deleted => false, :is_active => true}, :order => 'name ASC')
      render :update do |page|
        page.replace_html "batch_list", :partial => "list_batches"
      end
    else
      render :update do |page|
        page.replace_html "batch_list", :text => ""
      end
    end
  end

  def subject_details_csv
    parameters={:sort_order => params[:sort_order], :subject_search => params[:subject_search], :course_id => params[:course]}
    csv_export('subject', 'subject_details', parameters)
  end

  def employee_subject_association
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @employees= Employee.paginate(:select => "first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number", :joins => [:employees_subjects, :employee_department], :group => "employees.id", :page => params[:page], :per_page => 20, :order => 'first_name ASC')
      emp_ids=@employees.collect(&:id)
      @subjects=EmployeesSubject.all(:select => "employees_subjects.employee_id ,subjects.name as subject_name, batches.name as batch_name ,courses.code", :conditions => {:employee_id => emp_ids, :subjects => {:is_deleted => false}, :batches => {:is_deleted => false, :is_active => true}}, :joins => " INNER JOIN `subjects` ON `subjects`.id = `employees_subjects`.subject_id INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :order => 'subject_name').group_by(&:employee_id)
    else
      @employees= Employee.paginate(:select => "first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number", :joins => [:employees_subjects, :employee_department], :group => "employees.id", :page => params[:page], :per_page => 20, :order => @sort_order)
      emp_ids=@employees.collect(&:id)
      @subjects=EmployeesSubject.all(:select => "employees_subjects.employee_id ,subjects.name as subject_name, batches.name as batch_name ,courses.code", :conditions => {:employee_id => emp_ids, :subjects => {:is_deleted => false}, :batches => {:is_deleted => false, :is_active => true}}, :joins => " INNER JOIN `subjects` ON `subjects`.id = `employees_subjects`.subject_id INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :order => 'subject_name').group_by(&:employee_id)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "employee_subject_details"
      end
    end
  end

  def employee_subject_association_csv
    parameters={:sort_order => params[:sort_order]}
    csv_export('employee', 'employee_subject_association', parameters)
  end

  def employee_payroll_details
    @departments=EmployeeDepartment.active_and_ordered(:select => "name,id")
    @sort_order = params[:sort_order]
    if params[:department_id].nil? or params[:department_id].blank?
      @employees = Employee.paginate(:select => "first_name, middle_name, last_name,employees.id, employee_departments.name as department_name, payroll_groups.name as payroll_group_name, employee_number", :joins => "LEFT OUTER JOIN employee_salary_structures ON employee_salary_structures.employee_id = employees.id LEFT OUTER JOIN payroll_groups ON payroll_groups.id = employee_salary_structures.payroll_group_id INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id", :include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :per_page => 10, :page => params[:page], :order => (@sort_order.nil? ? 'first_name ASC' : @sort_order))
    else
      @employees = Employee.paginate(:select => "first_name, middle_name, last_name,employees.id, employee_departments.name as department_name, payroll_groups.name as payroll_group_name, employee_number", :joins => "LEFT OUTER JOIN employee_salary_structures ON employee_salary_structures.employee_id = employees.id LEFT OUTER JOIN payroll_groups ON payroll_groups.id = employee_salary_structures.payroll_group_id INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id", :include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :conditions => ["employee_departments.id=?", params[:department_id]], :per_page => 10, :page => params[:page], :order => (@sort_order.nil? ? 'first_name ASC' : @sort_order))
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "payroll_details"
      end
    end
  end

  def employee_payroll_details_csv
    parameters={:sort_order => params[:sort_order], :department_id => params[:department_id]}
    csv_export('employee', 'employee_payroll_details', parameters)
  end

  def exam_schedule_details
    @courses=Course.all(:select => "course_name,section_name,id", :conditions => {:is_deleted => false}, :order => 'course_name ASC')
    @sort_order=params[:sort_order]
    if params[:batch_id].nil? or params[:batch_id][:batch_ids].blank?
      if @sort_order.nil?
        @examgroups=ExamGroup.paginate(:select => "exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code", :conditions => {:is_published => true, :result_published => false, :batches => {:is_deleted => false, :is_active => true}}, :joins => [:batch => :course], :page => params[:page], :per_page => 10, :order => 'name ASC')
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select => "subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id", :conditions => {:exam_groups => {:result_published => false, :is_published => true, :id => exam_group_ids}}, :joins => [:exam_group, :subject]).group_by(&:exam_group_id)
      else
        @examgroups=ExamGroup.paginate(:select => "exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code", :conditions => {:is_published => true, :result_published => false, :batches => {:is_deleted => false, :is_active => true}}, :joins => [:batch => :course], :page => params[:page], :per_page => 10, :order => @sort_order)
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select => "subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id", :conditions => {:exam_groups => {:result_published => false, :is_published => true, :id => exam_group_ids}}, :joins => [:exam_group, :subject]).group_by(&:exam_group_id)
      end
    else
      if @sort_order.nil?
        @examgroups=ExamGroup.paginate(:select => "exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code", :conditions => {:is_published => true, :result_published => false, :batches => {:id => params[:batch_id][:batch_ids]}}, :joins => [:batch => :course], :page => params[:page], :per_page => 10, :order => 'name ASC')
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select => "subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id", :conditions => {:exam_groups => {:result_published => false, :is_published => true, :id => exam_group_ids}}, :joins => [:exam_group, :subject]).group_by(&:exam_group_id)
      else
        @examgroups=ExamGroup.paginate(:select => "exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code", :conditions => {:is_published => true, :result_published => false, :batches => {:id => params[:batch_id][:batch_ids]}}, :joins => [:batch => :course], :page => params[:page], :per_page => 10, :order => @sort_order)
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select => "subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id", :conditions => {:exam_groups => {:result_published => false, :is_published => true, :id => exam_group_ids}}, :joins => [:exam_group, :subject]).group_by(&:exam_group_id)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "exam_details"
      end
    end
  end

  def batch_list
    unless params[:course_id].blank?
      @active_batches=Batch.all(:select => "name,id,course_id", :conditions => {:course_id => params[:course_id], :is_deleted => false, :is_active => true}, :order => 'name ASC')
      @inactive_batches=Batch.all(:select => "name,id,course_id", :conditions => {:course_id => params[:course_id], :is_active => false}, :order => 'name ASC')
      render :update do |page|
        if (@active_batches.blank? and @inactive_batches.blank?)
          page.replace_html "batch_lists", :text => "<div class='batch-message' style='margin-top:13px;'>#{t('no_batches_in_this_course')}</div>"

        else
          page.replace_html "batch_lists", :partial => "batch_list"
        end
      end
    else
      @inactive_batches=[]
      @active_batches=[]
      render :update do |page|
        page.replace_html "batch_lists", :partial => "batch_list"
      end
    end
  end

  def batch_list_active
    unless params[:course_id].blank?
      @active_batches=Batch.all(:select => "name,id,course_id", :conditions => {:course_id => params[:course_id], :is_deleted => false, :is_active => true}, :order => 'name ASC')
      render :update do |page|
        page.replace_html "siblings-table", :text => ""
        if (@active_batches.blank?)
          page.replace_html "batch_lists", :text => "<div class='batch-message' style='margin-top:13px;'>#{t('no_batches_in_this_course')}</div>"

        else
          page.replace_html "batch_lists", :partial => "batch_list_active"
        end
      end
    else
      @active_batches=[]
      render :update do |page|
        page.replace_html "batch_lists", :text => ""
      end
    end
  end

  def exam_schedule_details_csv
    parameters={:sort_order => params[:sort_order], :batch_id => params[:batch_id]}
    csv_export('exam_group', 'exam_schedule_details', parameters)
  end

  def fee_collection_details
    @courses = Course.all(:select => "course_name,section_name,id", :conditions => {:is_deleted => false}, :order => 'course_name ASC')
    @sort_order = params[:sort_order]

    fetch_options = {}
    fetch_options[:select] = "finance_fee_collections.name, finance_fee_collections.start_date,
                              finance_fee_collections.end_date, finance_fee_collections.due_date, batches.id as batch_id,
                              batches.name as batch_name, courses.code,finance_fee_categories.name as category_name"
    fetch_options[:joins] =  "INNER JOIN fee_collection_batches
                                      ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
                              INNER JOIN batches on batches.id=fee_collection_batches.batch_id
                              INNER JOIN `finance_fee_categories`
                                      ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id
                              INNER JOIN `courses` ON `courses`.id = `batches`.course_id
                               #{active_account_joins}"
    # fetch_options[:conditions] = {:batches => {:is_deleted => false, :is_active => true}, :is_deleted => false}
    fetch_options[:conditions] = ["batches.is_deleted = false AND batches.is_active = true AND
                                   finance_fee_collections.is_deleted = false AND #{active_account_conditions}"]
    if params[:batch_id].present?
      fetch_options[:conditions][0] += " AND batches.id IN (?)"
      fetch_options[:conditions] << params[:batch_id][:batch_ids]
    end    

    fetch_options[:page] = params[:page]
    fetch_options[:per_page] = 20
    fetch_options[:order] = @sort_order.present? ? @sort_order : "name ASC"

    @fee_collection= FinanceFeeCollection.paginate(fetch_options)

    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "fees_collection_details"
      end
    end
  end

  def fee_collection_details_csv
    parameters={:sort_order => params[:sort_order], :batch_id => params[:batch_id]}
    csv_export('finance_fee_collection', 'fee_collection_details', parameters)
  end

  def course_fee_defaulters
    @sort_order=params[:sort_order]||nil
    @courses = Course.paginate(:select => "courses.id, courses.course_name, courses.code, courses.section_name,
                                           sum(balance) balance, count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count",
      :joins => "INNER JOIN batches on batches.course_id=courses.id
                                          INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",
      :group => 'courses.id', :per_page => 20, :page => params[:page], :order => @sort_order)
    #    @total_amount=Course.sum('balance',:joins=>"INNER JOIN batches on batches.course_id=courses.id INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true}})
    @total_amount = Course.sum('balance', :joins => "INNER JOIN batches on batches.course_id=courses.id INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id", :conditions => {:batches => {:is_deleted => false}})

    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "course_fees_defaulters"
      end
    end
  end

  def course_fee_defaulters_csv
    parameters={:sort_order => params[:sort_order]}
    csv_export('course', 'course_fee_defaulters', parameters)
  end

  def batch_fee_defaulters
    @sort_order=params[:sort_order]||nil
    @employees = Employee.all(:select => 'batches.id as batch_id, employees.first_name, employees.last_name,
                                          employees.middle_name, employees.id as employee_id, employees.employee_number',
      :conditions => {:batches => {:course_id => params[:id]}}, :joins => [:batches]).group_by(&:batch_id)
    @batches = Batch.paginate(:select => "batches.id, batches.course_id, batches.name, batches.start_date,
                                          batches.end_date, sum(balance) balance,
                                          count(DISTINCT collection_id) fee_collections_count", :joins => "INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id", :group => 'batches.id', :per_page => 20, :include => :course, :page => params[:page], :conditions => {:course_id => params[:id]})
    @total_amount = Batch.sum('balance', :joins => "INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",
      :conditions => {:course_id => params[:id]})
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_fees_defaulters"
      end
    end
  end

  def batch_fee_defaulters_csv
    parameters={:sort_order => params[:sort_order], :course_id => params[:id]}
    csv_export('batch', 'batch_fee_defaulters', parameters)
  end

  def batch_fee_collections
    @total_amount = FinanceFeeCollection.sum("IF(students.id IS NOT NULL and finance_fee_collections.is_deleted = false and
       finance_fee_collections.due_date < '#{Date.today}' and finance_fees.balance >0,finance_fees.balance,0)",
      :joins => "INNER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id
                  INNER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id
                  INNER JOIN students on students.id=finance_fees.student_id #{active_account_joins}",
      :conditions => ["#{active_account_conditions} AND finance_fees.batch_id=? and finance_fee_collections.is_deleted=? and
                        finance_fee_collections.due_date < ? and finance_fees.balance> ?",
        params[:id], false, Date.today, 0.0]).to_f

    @fee_collections = [
      {
        :finance_fee_collection =>
          {
          :select => "finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,
                        finance_fee_collections.end_date,finance_fee_collections.due_date,
                        sum(IF(students.id IS NOT NULL AND finance_fee_collections.is_deleted = false AND
                               finance_fee_collections.due_date < '#{Date.today}' AND
                               finance_fees.balance > 0.0,finance_fees.balance,0)) as balance,
                        count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",
          :joins => "INNER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id
                       INNER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id
                       INNER JOIN students on students.id=finance_fees.student_id
                       #{active_account_joins}",
          :conditions => ["#{active_account_conditions} AND finance_fees.batch_id=? and finance_fee_collections.is_deleted=? and
                             finance_fee_collections.due_date < ? and finance_fees.balance> ?", params[:id], false, Date.today, 0.0],
          :group => "id",
          :order => "balance DESC"
        }
      }
    ]

    if FedenaPlugin.can_access_plugin?("fedena_transport") #and FedenaPlugin.can_access_plugin?("fedena_hostel")
      @fee_collections += [{
          :transport_fee_collection =>
            {
            :select => "transport_fee_collections.id,transport_fee_collections.name,transport_fee_collections.start_date,
                        transport_fee_collections.end_date,transport_fee_collections.due_date,
                        sum(IF(receiver_type='Student' and students.id IS NOT NULL and
                               transport_fee_collections.is_deleted = false and
                               transport_fee_collections.due_date < '#{Date.today}' and transport_fees.balance > 0.0,
                               transport_fees.balance,0)) as balance,
                        count(DISTINCT IF(receiver_type='Student' and transport_fees.balance!='0.0' and
                                          students.id IS NOT NULL,transport_fees.id,NULL)) as students_count",
            :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id =transport_fee_collections.id
                       INNER JOIN students on transport_fees.receiver_id=students.id and transport_fees.receiver_type='Student'
                       INNER JOIN batches on students.batch_id=batches.id #{active_account_joins(true, 'transport_fee_collections')}",
            :conditions => ["#{active_account_conditions(true, 'transport_fee_collections')} AND batches.id=? and
                             transport_fee_collections.is_deleted=? and transport_fee_collections.due_date < '#{Date.today}' and
                             transport_fees.balance > ? AND `transport_fees`.`is_active` = ?", params[:id], false, 0.0, true],
            :group => "transport_fee_collections.id",
            :order => "balance DESC"
          }
        }]

      @total_amount += TransportFeeCollection.sum("(IF(transport_fees.receiver_type='Student' and students.id IS NOT NULL and
        transport_fee_collections.is_deleted=false and transport_fee_collections.due_date < '#{Date.today}' and
        transport_fees.balance >0,transport_fees.balance,0))",
        :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                   INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'
                   INNER JOIN batches on students.batch_id=batches.id #{active_account_joins(true, 'transport_fee_collections')}",
        :conditions => ["#{active_account_conditions(true, 'transport_fee_collections')} and batches.id = ? AND
         `transport_fees`.`is_active` = ?", params[:id], true]).to_f
    end

    if FedenaPlugin.can_access_plugin?("fedena_hostel") #and !FedenaPlugin.can_access_plugin?("fedena_transport")
      @fee_collections += [{
          :hostel_fee_collection =>
            {
            :select => "hostel_fee_collections.id,hostel_fee_collections.name,hostel_fee_collections.start_date,
                        hostel_fee_collections.end_date,hostel_fee_collections.due_date,
                        sum(IF(students.id IS NOT NULL and hostel_fee_collections.is_deleted = false and
                               hostel_fee_collections.due_date < '#{Date.today}' and hostel_fees.balance > 0.0,
                               hostel_fees.balance,0)) as balance,
                        count(DISTINCT IF(students.id IS NOT NULL and hostel_fees.balance!='0.0',hostel_fees.id,NULL)) as students_count",
            :joins => "INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id
                       INNER JOIN students on hostel_fees.student_id=students.id
                       INNER JOIN batches on students.batch_id=batches.id #{active_account_joins(true, 'hostel_fee_collections')}",
            :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND batches.id=? and
                             hostel_fee_collections.is_deleted=? and hostel_fee_collections.due_date < ? and
                             hostel_fees.balance > ? AND `hostel_fees`.`is_active` = ?", params[:id], false, Date.today, 0.0, true],
            :group => "hostel_fee_collections.id", :order => "balance DESC"
          }
        }]

      @total_amount += HostelFeeCollection.sum(
        "(IF(students.id IS NOT NULL and hostel_fee_collections.is_deleted =false and
             hostel_fee_collections.due_date < '#{Date.today}' and hostel_fees.balance >0,hostel_fees.balance,0))",
        :joins => "INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                   INNER JOIN students on students.id=hostel_fees.student_id
                   INNER JOIN batches on students.batch_id=batches.id #{active_account_joins(true, 'hostel_fee_collections')}",
        :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND batches.id = ? AND
                         `hostel_fees`.`is_active` = ?", params[:id], true]
      ).to_f
    end

    @fee_collections = @fee_collections.model_paginate(:page => params[:page], :per_page => 20)

    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_fees_collections"
      end
    end
  end

  def batch_fee_collections_csv
    parameters = {:batch_id => params[:id]}
    csv_export('finance_fee_collection', 'batch_fee_collections', parameters)
  end

  def students_fee_defaulters
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      if params[:transaction_class]=="HostelFeeCollection"
        @students=Student.paginate(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => [:hostel_fees],
          :conditions => [
            "hostel_fees.hostel_fee_collection_id=? and students.batch_id=? AND `hostel_fees`.`is_active` = ? and hostel_fees.balance > ?", params[:collection_id], params[:id], true, 0.0],
          :per_page => 20, :page => params[:page],
          :order => "balance DESC"
        )
        @total_amount=Student.sum("balance",
          :joins => [:hostel_fees],
          :conditions => [
            "hostel_fees.hostel_fee_collection_id=? and students.batch_id=? AND `hostel_fees`.`is_active` = ? and hostel_fees.balance > ?",
            params[:collection_id], params[:id], true, 0.0]
        )
      elsif params[:transaction_class]=="TransportFeeCollection"
        @students=Student.paginate(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id",
          :conditions => [
            "transport_fees.transport_fee_collection_id=? and students.batch_id=? AND `transport_fees`.`is_active` = ? and transport_fees.balance > ?",
            params[:collection_id], params[:id], true, 0.0
          ],
          :per_page => 20,
          :page => params[:page],
          :order => "balance DESC"
        )
        @total_amount=Student.sum("balance",
          :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id",
          :conditions => [
            "transport_fees.transport_fee_collection_id=? and transport_fees.balance > ? and students.batch_id=? AND `transport_fees`.`is_active` = ?",
            params[:collection_id], 0.0, params[:id], true
          ]
        )
      else
        @students=Student.paginate(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance > ? and finance_fees.batch_id=?", params[:collection_id], 0.0, params[:id]], :per_page => 20, :page => params[:page], :order => "balance DESC")
        @total_amount=Student.sum("balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?", params[:collection_id], 0.0, params[:id]])
      end
    else
      if params[:transaction_class]=="HostelFeeCollection"
        @students=Student.paginate(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => [:hostel_fees],
          :conditions => ["hostel_fees.hostel_fee_collection_id=? and students.batch_id=? AND `hostel_fees`.`is_active` = ? and hostel_fees.balance > ?", params[:collection_id], params[:id], true, 0.0],
          :per_page => 20,
          :page => params[:page],
          :order => @sort_order)
        @total_amount=Student.sum("balance", :joins => [:hostel_fees], :conditions => ["hostel_fees.hostel_fee_collection_id=? and students.batch_id=? AND `hostel_fees`.`is_active` = ? and hostel_fees.balance > ?", params[:collection_id], params[:id], true, 0.0])
      elsif params[:transaction_class]=="TransportFeeCollection"
        @students=Student.paginate(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id",
          :conditions => ["transport_fees.transport_fee_collection_id=? and students.batch_id=? and transport_fees.balance > ?", params[:collection_id], params[:id], 0.0],
          :per_page => 20,
          :page => params[:page],
          :order => @sort_order)
        @total_amount=Student.sum("balance",
          :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id", :conditions => ["transport_fees.transport_fee_collection_id=? and transport_fees.balance > ? and students.batch_id=?", params[:collection_id], 0.0, params[:id]])
      else
        @students=Student.paginate(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance > ? and finance_fees.batch_id=?", params[:collection_id], 0.0, params[:id]], :per_page => 20, :page => params[:page], :order => @sort_order)
        @total_amount=Student.sum("balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?", params[:collection_id], 0.0, params[:id]])
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "students_fees_defaulters"
      end
    end
  end

  def students_fee_defaulters_csv
    parameters={:sort_order => params[:sort_order], :fee_collection_id => params[:collection_id], :batch_id => params[:id], :transaction_class => params[:transaction_class]}
    csv_export('student', 'students_fee_defaulters', parameters)
  end

  def student_wise_fee_defaulters
    @sort_order = params[:sort_order] || nil
    @columns = params[:columns] || {}
    @additional_fields = StudentAdditionalField.get_fields
    @all_students = Student.all(:select => 'students.roll_number,students.id,students.admission_no,students.first_name,
                                            students.middle_name,students.last_name,students.batch_id,sum(balance) balance, students.immediate_contact_id,
                                            count(IF(balance>0,balance,NULL)) fee_collections_count, students.sibling_id, students.phone2',
      :joins => "INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",
      :group => 'students.id', :include => {:batch => :course}, :order => @sort_order)
    @students = @all_students.paginate(:per_page => 20, :page => params[:page], :order => @sort_order)
    @additional_details = Student.fetch_additional_details(@students)
    @total_amount = Student.sum('balance', :joins => "INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id")
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "student_wise_fees_defaulters"
        page << "remove_popup_box();"
      end
    end
  end
  
  def fee_defaulters_columns
    @active_fields =  StudentAdditionalField.active 
    @selected_columns = params[:columns] || {}
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{t(:customize_columns)}', 'popup_class' : 'column_form'})"
      page.replace_html 'popup_content', :partial => (params[:fee_collection].present? ? 'fee_collection_report_columns_list' : 'columns_list')
    end
  end
  
  def fee_collection_selectors
    @selected_columns = params[:columns] || {}
    render :update do |page|
      page.replace_html "column_div", :partial => "fee_collection_report_selector"
      page << "remove_popup_box();"
    end
  end

  def student_wise_fee_defaulters_csv
    parameters={:sort_order => params[:sort_order], :columns => params[:columns]}
    csv_export('student', 'students_wise_fee_defaulters', parameters)
  end

  def student_wise_fee_collections
    @student = Student.find params[:id]
    @total_amount = FinanceFeeCollection.sum("balance",
      :joins => "LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id
                      INNER JOIN students on students.id=finance_fees.student_id
                      #{active_account_joins}",
      :conditions => ["#{active_account_conditions} AND students.id=? and finance_fee_collections.is_deleted=? and
                       finance_fee_collections.due_date < ?", params[:id], false, Date.today]).to_f
    @fee_collections = [{
        :finance_fee_collection =>
          {
          :select => "finance_fee_collections.name, finance_fee_collections.start_date,
                                finance_fee_collections.end_date,finance_fee_collections.due_date,balance",
          :joins => "LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id = finance_fee_collections.id
                                    INNER JOIN students on students.id=finance_fees.student_id
                               #{active_account_joins}",
          :conditions => ["#{active_account_conditions} AND students.id=? and finance_fee_collections.is_deleted=? and
                                     finance_fee_collections.due_date < ? and finance_fees.balance > ?", params[:id],
            false, Date.today, 0.0], :order => "balance DESC"
        }
      }
    ]

    if FedenaPlugin.can_access_plugin?("fedena_hostel") #and FedenaPlugin.can_access_plugin?("fedena_transport")
      @total_amount += HostelFeeCollection.sum("hostel_fees.balance",
        :joins => "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                   #{active_account_joins(true,'hostel_fee_collections')}",
        :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND
          hostel_fee_collections.due_date < ? AND `hostel_fee_collections`.`is_deleted` = ? AND
          `hostel_fees`.`student_id` = ? AND `hostel_fees`.`is_active` = ?",
          Date.today, false, params[:id], true]).to_f

      @fee_collections += [
        {
          :hostel_fee_collection =>
            {
            :select => "hostel_fee_collections.name,start_date,end_date,due_date,hostel_fees.balance as balance",
            :joins => "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                       #{active_account_joins(true, 'hostel_fee_collections')}",
            :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND
                             `hostel_fee_collections`.`is_deleted` = ? AND `hostel_fees`.`student_id` = ? and
                              hostel_fees.balance > ? AND hostel_fee_collections.due_date < ? AND
                              `hostel_fees`.`is_active` = true", false, params[:id], 0.0, Date.today ],
            :order => "balance DESC"
          }
        }
      ]
    end

    if FedenaPlugin.can_access_plugin?("fedena_transport") #("fedena_hostel")
      @total_amount += TransportFeeCollection.sum("transport_fees.balance",
        :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                   #{active_account_joins(true, 'transport_fee_collections')}",
        :conditions => ["#{active_account_conditions(true, 'transport_fee_collections')} AND
                         transport_fee_collections.is_deleted = ? AND `transport_fees`.`receiver_id` = ? AND
                         `transport_fees`.`receiver_type` = 'Student' AND `transport_fees`.`is_active` = ?", false,
          params[:id], true]).to_f

      @fee_collections += [
        {
          :transport_fee_collection =>
            {
            :select => "transport_fee_collections.id,transport_fee_collections.name,
                              start_date,end_date,due_date,transport_fees.balance as balance",
            :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                             #{active_account_joins(true, 'transport_fee_collections')}",
            :conditions => ["#{active_account_conditions(true, 'transport_fee_collections')} AND
                                   transport_fee_collections.is_deleted = ? AND `transport_fees`.`receiver_id` = ? AND
                                   `transport_fees`.`receiver_type` = 'Student' and transport_fees.balance > ? AND
                                   transport_fee_collections.due_date < ? AND `transport_fees`.`is_active` = ?",
              false, params[:id], 0.0, Date.today, true], :order => "balance DESC"
          }
        }
      ]
    end

    @fee_collections = @fee_collections.model_paginate(:page => params[:page], :per_page => 20)

    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "student_wise_fees_collections"
      end
    end
  end

  def student_wise_fee_collections_csv
    parameters={:student_id => params[:id]}
    csv_export('student', 'student_wise_fee_collections', parameters)
  end


  def search_ajax

    query = params[:query]
    if query.length>= 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%",
          "#{query}", "#{query}"],
        :order => "batch_id asc,first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false

  end


  def batch_fees_headwise_report
    @courses=Course.active
    course_id=params[:course].present? ? params[:course][:course_id] : []
    joins = "INNER JOIN finance_fees ON finance_fees.student_id = students.id 
             INNER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id
             INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
              #{active_account_joins}"
    cond = active_account_conditions
    if request.xhr?
      if params[:batch_id].present?
        @batch_ids=params[:batch_id][:batch_ids]
        @students=Student.paginate(:select => "DISTINCT students.*",
          :conditions => ["finance_fees.batch_id IN (?) AND #{cond}", @batch_ids],
          :per_page => 10, :page => params[:page],
          :joins => joins, #[{:finance_fees => {:finance_fee_collection => :fee_collection_batches}}],
          :include => [{:finance_fees => [{:finance_fee_collection => [:fee_account, {:collection_particulars =>
                        {:finance_fee_particular => :receiver}}, {:collection_discounts =>
                        {:fee_discount => :receiver}}]}, :finance_transactions, :batch,
                {:tax_collections => :tax_slab}]}],
          :order => 'first_name ASC')
      elsif (course_id.blank?)
        @students=Student.paginate(:select => "DISTINCT students.*", :conditions => cond,
          :per_page => 10, :page => params[:page],
          :joins => joins, #[{:finance_fees => {:finance_fee_collection => :fee_collection_batches}}],
          :include => [{:finance_fees => [{:finance_fee_collection => [:fee_account, {:collection_particulars =>
                        {:finance_fee_particular => :receiver}}, {:collection_discounts =>
                        {:fee_discount => :receiver}}]}, :finance_transactions, :batch, :student_category,
                {:tax_collections => :tax_slab}]}],
          :order => 'first_name ASC')
      else
        @students=[]
      end
      render :update do |page|
        page.replace_html "information", :partial => "batch_fee_headwise_report"
      end
    else
      @students=Student.paginate(:select => "DISTINCT students.*", :per_page => 10,
        :page => params[:page], :joins => joins, :conditions => cond, #:joins => [{:finance_fees => {:finance_fee_collection => :fee_collection_batches}}],
        :include => [{:finance_fees =>
              [{:finance_fee_collection => [:fee_account, {:collection_particulars =>
                      {:finance_fee_particular => :receiver}}, {:collection_discounts =>
                      {:fee_discount => :receiver}}]}, :finance_transactions, :batch, :student_category,
              {:tax_collections => :tax_slab}]}],
        :order => 'first_name ASC')
    end
  end

  def batch_selector
    if params[:start_date].present? and params[:end_date].present?
      @start_date=params[:start_date].to_date
      @end_date=params[:end_date].to_date
    else
      @start_date=Date.today
      @end_date=Date.today
    end
    @errors = []
    @inactive_batches = false

    if @start_date > @end_date
      @errors << "Start date cannot be greater than end date"
    else
      if params[:val].present? && params[:val].to_i == 2
        # inactive batches
        @inactive_batches = true
        if (@end_date - @start_date) > 365
          @errors << "Date range cannot be greater than one year"
        else
          #@batches=Batch.all(:select => "name,id,course_id",:include=>:course, :conditions => ["is_deleted = false and is_active = false and ((start_date >= ? and start_date <= ? ) and (end_date >= ? and end_date <= ?) ) ", @start_date, @end_date, @start_date, @end_date ], :order => 'name ASC')
          @batches=Batch.all(:joins=>:course, :conditions => ["batches.is_deleted = false and batches.is_active = false and ((batches.start_date >= ? and batches.start_date <= ? ) or (batches.end_date >= ? and batches.end_date <= ?) or (batches.start_date <= ? and batches.end_date >= ?)) ",
              @start_date, @end_date, @start_date, @end_date, @start_date, @end_date], :include=>:course, :order => 'courses.course_name ASC, batches.name ASC')
          if !@batches.present?
            @errors << "No Batches Present"
          end
        end
      else
        @batches=Batch.all(:joins=>:course, :include=>:course, :conditions => ["batches.is_deleted=false and batches.is_active=true"], :order => 'courses.course_name ASC, batches.name ASC')
        if !@batches.present?
          @errors << "No Batches Present"
        end
      end
    end

    render :update do |page|
      page.replace_html "batch_selector", :partial => "batch_selector"
    end
  end

  def fee_collection_report
    if params[:start_date].present? and params[:end_date].present?
      @start_date=params[:start_date].to_date
      @end_date=params[:end_date].to_date
    else
      @start_date=Date.today
      @end_date=Date.today
    end

  end


  def student_fees_headwise_report
    @student=Student.find(params[:id])
    @batches=@student.all_batches.reverse
    @student_batch_fees = {}
    @batches.map do |batch|
      @student_batch_fees[batch.id] = @student.fees_list_by_batch(batch.id)
    end if @batches.present?
  end

  def student_fees_headwise_report_pdf
    @student=Student.find(params[:id])
    @batches=@student.all_batches.reverse
    @student_batch_fees = {}
    @batches.map do |batch|
      @student_batch_fees[batch.id] = @student.fees_list_by_batch(batch.id)
    end if @batches.present?
    render :pdf => "student_fees_headwise_report_pdf", :margin => {:left => 15, :right => 15,
      :top => 40, :bottom => 20}, #,:header=>{:html=> {:template=> 'layouts/pdf_header.html.erb'}}  #
    :show_as_html=> (params[:d].present? and params[:d].to_i == 1)
  end

  # def student_fees_headwise_report_csv
  #   @studentm=Student.find(params[:id])
  #   @batches=@student.all_batches.reverse
  # end

  def fee_collection_head_wise_report
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true},
      :joins => :course, :select => "`batches`.*, CONCAT(courses.code,'-',
                                                                                        batches.name) AS course_full_name",
      :order => "course_full_name")
    @dates = []
    if request.xhr?
      @finance_fee_collection = FinanceFeeCollection.find_by_id(params[:fee_collection_id],
        :joins => "#{active_account_joins}", :conditions => "#{active_account_conditions}")
      @students = Student.paginate(:select => "DISTINCT students.*",
        :conditions => ["#{active_account_conditions(true, 'ffc')} AND finance_fees.fee_collection_id = ? AND
                         finance_fees.batch_id=?", params[:fee_collection_id], params[:batch_id]],
        :per_page => 10, :page => params[:page],
        :joins => "INNER JOIN finance_fees ON finance_fees.student_id = students.id
                   INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                    #{active_account_joins(true, 'ffc')}",
        :include => {:batch => :course}, :order => 'first_name ASC')
      student_ids = @students.map(&:id)
      @student_fees = student_ids.present? ? FinanceFee.all(:conditions => {:student_id => student_ids,
          :fee_collection_id => @finance_fee_collection.id }, :include => [{:finance_fee_collection =>
              [{:collection_particulars => {:finance_fee_particular =>:receiver}}, {:collection_discounts =>
                  {:fee_discount=>:receiver}}]}, :finance_transactions, :batch, :student_category,
          {:tax_collections => :tax_slab}]) : []

      @tax_present = @student_fees.map {|x| x.tax_enabled? and x.tax_collections.present? }.
        uniq.include?(true)
      @student_fees = @student_fees.group_by {|ff| ff.student_id }
      render :update do |page|
        page.replace_html "information", :partial => "fee_collection_head_wise_report"
      end
    end
  end

  def update_fees_collections
    @batch = Batch.find(params[:batch_id]) if params[:batch_id].present?
    @dates = @batch.finance_fee_collections.all(:joins => "#{active_account_joins}",
      :conditions => "#{active_account_conditions}") if @batch.present?
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collections"
    end
  end


  def fee_collection_head_wise_report_csv
    parameters={:batch_id => params[:batch_id], :fee_collection_id => params[:fee_collection_id]}
    csv_export('finance_fee', 'csv_fee_collection_fees_head_wise_report', parameters)
  end

  def batch_head_wise_fees_csv
    parameters={:batch_ids => params[:batch_ids]}
    csv_export('finance_fee', 'csv_batch_fees_head_wise_report', parameters)
  end

  def collection_report_csv
    parameters={:batch_ids => params[:b].present? ? params[:b] : [] ,:start_date=>params[:start_date], :end_date=>params[:end_date], :active=>params[:active], :columns => params[:columns]}
    csv_export('finance_fee', 'csv_collection_report', parameters)
  end

  def send_sms
    if params[:send_sms].present?
      Delayed::Job.enqueue(DelayedSendSmsToFeeDefaulters.new(params[:send_sms][:student_ids]),{:queue => 'sms'})
      if request.xhr?
        render :update do |page|
          if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
            page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
          else
            page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated')}</p>"
          end
        end
      end
    elsif params[:send_all].present?
      @students = Student.fee_defaulters
      @students_id = @students.collect(&:id)
      @students_id.each_slice(150) do |defaulter_ids|
        Delayed::Job.enqueue(DelayedSendSmsToFeeDefaulters.new(defaulter_ids),{:queue => 'sms'})
      end
      if request.xhr?
        render :update do |page|
          if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("SMSManagement"))
            page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
          else
            page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated')}</p>"
          end
          page.replace_html 'send_all_button', :partial => "fees_defaulter_button"
        end
      end
    else
      render :update do |page|
        page.replace_html 'flash-div',:text=>"<p class=\"flash-msg\">#{t('no_student_selected')}</p>"
      end
    end

  end

  def siblings_report
    @sort_order = params[:sort_order] || "first_name ASC"
    @batch_ids = params[:batch_ids].present? ? params[:batch_ids] : (params[:batch_id].present? ? params[:batch_id][:batch_ids] : nil)
    if request.xhr? and params[:type].present? and params[:type] == "course"
      @type = 'course'
      @students = Student.student_with_siblings(@sort_order).with_batch(@batch_ids).paginate(:page => params[:page], :per_page =>10)
    else
      @type = 'school'
      @students = Student.primary_student_with_siblings(@sort_order).paginate(:page => params[:page], :per_page => 10);
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "siblings-table", :partial => "siblings_report"
        page.replace_html "reveal-inactive", :text => "" if @type == 'school'
      end
    end
  end

  def siblings_course_select
    if request.xhr?
      @courses = Course.all(:select => "course_name,section_name,id", :conditions => {:is_deleted => false}, :order => 'course_name ASC')
      render :update do |page|
        page.replace_html "reveal-inactive", :partial => "sibling_course"
        page.replace_html "siblings-table", :text => ""
      end
    end
  end

  def siblings_report_csv
    parameters = {:batch_id => params[:batch_id], :type => params[:type], :sort_order => params[:sort_order]}
    csv_export('student', 'csv_siblings_report', parameters)
  end

  def pdf_reports

    if (MultiSchool rescue false)
      @jobs=Delayed::Job.all(:conditions=>{:queue => "additional_reports"}).select { |j| j.payload_object.class.name=="DelayedAdditionalReportPdf" and MultiSchool.current_school.id== (j.payload_object.instance_variable_get(:@school_id) || (j.payload_object.respond_to?(:school_id) && j.payload_object.school_id))}
    else
      @jobs=Delayed::Job.all(:conditions=>{:queue => "additional_reports"}).select { |j| j.payload_object.class.name=="DelayedAdditionalReportPdf" }
    end
    @pdf_report=AdditionalReportPdf.find_by_model_name_and_method_name(params[:model], params[:method])

  end
  
  def pdf_report_download
    upload = AdditionalReportPdf.find(params[:id])
    send_file upload.pdf_report.path,
      :filename => upload.pdf_report_file_name,
      :type => upload.pdf_report_content_type,
      :disposition => 'pdf_report'
  end
  
end
private

def csv_export(model, method, parameters)
  csv_report=AdditionalReportCsv.find(:first, :conditions=>{:model_name=>model, :method_name=>method})
  if csv_report.nil?
    csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
    if csv_report.save
      Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
    end
  else
    unless csv_report.status
      if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    end 
  end
  flash[:notice]="#{t('csv_report_is_in_queue')}" if csv_report.status
  redirect_to :action => :csv_reports, :model => model, :method => method
end

def discount_migration(a, b)
  discounts=[]
  b.collect(&:disc).uniq.compact.each do |name|
    a.each do |set|
      w=b.find_all_by_disc(name)
      e=w.collect(&:name)
      discounts << name
      new_attr=name.gsub(/[^a-zA-Z0-9]/, "_")
      if e.include? set.name
        disc_ids=w.find_all_by_name(set.name).collect(&:disc_id).uniq.compact
        h=[]
        disc_ids.each { |d| h<<"#{FedenaPrecision.set_and_modify_precision(w.find_by_disc_id(d).disc_amount.to_f)} #{w.find_by_disc_id(d).disc_amount.last=='%' ? '%' : ''}" }
        set["dis_"+new_attr]=h.join(',')
      else
        set["dis_"+new_attr]='NA'
      end
    end
  end
  return discounts.uniq
end

def particular_migration(a, b)
  particulars=[]
  b.collect(&:partname).uniq.compact.each do |name|
    a.each do |set|
      w=b.find_all_by_partname(name)
      e=w.collect(&:name)
      particulars << name
      new_attr=name.gsub(/[^a-zA-Z0-9]/, "_")
      if e.include? set.name
        part_ids=w.find_all_by_name(set.name).collect(&:part_id).uniq.compact
        h=[]
        part_ids.each { |d| h<<FedenaPrecision.set_and_modify_precision(w.find_by_part_id(d).particular.to_f) }
        set["par_"+new_attr]=h.join(',')
      else
        set["par_"+new_attr]='NA'
      end
    end
  end
  return particulars.uniq
end
