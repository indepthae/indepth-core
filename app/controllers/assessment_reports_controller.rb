class AssessmentReportsController < ApplicationController
  before_filter :login_required
  before_filter :validate_application_sms, :only => [:send_result_publish_notification]
  filter_access_to :all, :except => [:students_term_reports, :student_term_report_pdf, :student_exam_reports, :student_exam_report_pdf,:student_plan_report_pdf,:generate_batch_wise_reports,:students_planner_reports,:generate_planner_reports,:generate_term_reports,:regenerate_reports,:publish_reports,:refresh_students,:refresh_report,:generate_exam_reports]
  filter_access_to [:student_plan_report_pdf,:generate_batch_wise_reports,:students_planner_reports,:generate_planner_reports,:generate_term_reports,:regenerate_reports,:publish_reports,:refresh_students,:refresh_report,:generate_exam_reports,:students_term_reports, :student_term_report_pdf, :student_exam_reports, :student_exam_report_pdf], :attribute_check=>true, :load_method => lambda { ((current_user.student? or current_user.parent?) and params[:student_id].present?) ? Student.find(params[:student_id]) : current_user}
  require 'lib/override_errors'
  helper OverrideErrors
  
  
  def settings
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @academic_year = @plan.academic_year
    if request.post?
      AssessmentReportSetting.set_setting_values(params[:assessment_report_setting], @plan.id)
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action=> 'settings', :assessment_plan_id => @plan.id
    else
      @student_fields = AssessmentReportSetting::SETTINGS_WITH_VALUES
      load_templates #Todo: Change to read from db
      @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::SETTINGS + (@report_template.try(:settings_keys) || []), @plan.id
      @student_additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
    end
    if request.xhr?
      render(:update) do |page|
        page.replace_html 'right-panel', :partial=>'report_settings'
      end
    end
  end
  
  def advanced_report_settings
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    if request.post?
      AssessmentReportSetting.set_setting_values(params[:assessment_report_setting], @plan.id)
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action=> 'settings', :assessment_plan_id => @plan.id
    else
      @setting = AssessmentReportSetting.get_multiple_settings_as_hash(
         AssessmentReportSetting::SCORE_SETTINGS + AssessmentReportSetting::GRADE_SCALE_SETTINGS + AssessmentReportSetting::SCORE_ROUNDING_SETTINGS, @plan.id
      )
      @grades = GradeSet.all(:joins => :grades, :group => "grade_sets.id")
      @mark_grades = @grades.to_a.select{|g| !g.direct_grade}
      @grade_sets =  GradeSet.find_by_id(@setting[:grade_set_id])
      render(:update) do |page|
        page.replace_html 'right-panel', :partial=>'advanced_report_settings'
      end
    end
  end
  
  def attendance_settings
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    if request.post?
      AssessmentReportSetting.set_setting_values(params[:attendance_settings], @plan.id)
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action=> 'settings', :assessment_plan_id => @plan.id
    else
      @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::ATTENDANCE_SETTINGS, @plan.id
      render(:update) do |page|
        page.replace_html 'right-panel', :partial=>'attendance_settings'
      end
    end
  end
  
  def remark_bank
    @remark_bank = RemarkBank.new
    @remark_template = @remark_bank.build_remark_template
  end
  
  def records_and_remarks_settings
    @plan = AssessmentPlan.find_by_id(params[:assessment_plan_id], :include => :remark_sets)
    AssessmentReportSetting.set_setting_values(params[:assessment_report_settings],@plan.id) if params[:assessment_report_settings].present?
    if request.post?
      @plan.update_remark_attributes({:remark_sets_attributes => params[:assessment_plan][:remark_sets_attributes]})
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action=> 'settings', :assessment_plan_id => @plan.id
    else
      get_record_settings
      @setting[:enable_student_records] = "1" if params[:enable_student_records] == "true"
      render :update do |page|
        page.replace_html 'right-panel', :partial=>'records_and_remarks_settings'
      end
    end
  end

  def manage_links
    @record_groups = RecordGroup.all
    @type = params[:type]
    if params[:gradebook_record_group_id].present?
      @gradebook_record_group = GradebookRecordGroup.find params[:gradebook_record_group_id]
    else
      @gradebook_record_group = GradebookRecordGroup.new(:assessment_plan_id => params[:assessment_plan_id],:priority => 999)
    end
    @gradebook_record_group.build_records(params[:type],false)
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('manage_links')}', 'popup_class' : 'popup_link_records'})"
      page.replace_html 'popup_content', :partial => 'popup_link_records'
    end
  end
  
  def save_record_group_links
    if params[:gradebook_record_group][:id].present?
      @gradebook_record_group = GradebookRecordGroup.find params[:gradebook_record_group][:id]
      @gradebook_record_group.attributes = params[:gradebook_record_group]
    else
      @gradebook_record_group = GradebookRecordGroup.new(params[:gradebook_record_group])
    end
    @gradebook_record_group.save
    @plan = AssessmentPlan.find @gradebook_record_group.assessment_plan_id
    get_record_settings
    @gradebook_record_group.build_records(@type,true)
    @setting[:enable_student_records] = "1"
    render :update do |page|
      page.replace_html 'right-panel', :partial=>'records_and_remarks_settings'
    end
  end
    
  def destroy
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    if params[:gradebook_record_id].present?
      record = GradebookRecord.find params[:gradebook_record_id]
    elsif params[:gradebook_record_group_id].present?
      record = GradebookRecordGroup.find params[:gradebook_record_group_id]
    end
    record.destroy
    get_record_settings
    @setting[:enable_student_records] = "1"
    render :update do |page|
      page.replace_html 'right-panel', :partial=>'records_and_remarks_settings'
    end
  end
  
  def reorder_record_groups
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @plan.attributes = params[:assessment_plan]
    @plan.save
    @plan.reload
    get_record_settings
    @setting[:enable_student_records] = "1"
    render :update do |page|
      page.replace_html 'right-panel', :partial=>'records_and_remarks_settings'
      page.replace_html 'flash-msg1', :text=>"<p class='flash-msg'>#{t('record_group_reorder_successfully')}</p>"
      page.replace_html 'flash-msg', :text=>"<script>j('#flash-msg').hide()</script>"
    end
  end
  
  def report_header_info
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash ["HeaderSpace","UseCbseLogo"], params[:plan_id]
    render :update do |page|
      page.replace_html 'report_desc',:partial=>'report_with_normal_header' if params[:id]=="0"
      page.replace_html 'report_desc',:partial=>'report_without_normal_header' if params[:id]=="1"
    end
  end
  
  def report_signature_info
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash ["Signature", "SignLeftText", "SignCenterText", "SignRightText"]+
      AssessmentReportSetting::SIGN_KEYS, params[:plan_id]
    render :update do |page|
      page.replace_html 'report_sign',:partial=>'report_with_signature' if params[:id]=="0"
      page.replace_html 'report_sign',:text=>'' if params[:id]=="1"
    end
  end
  
  def preview
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @general_records = AssessmentReportSetting.result_as_hash @plan.id
    @batch=Batch.active.last(:joins=>:students)
    @grading_levels = (@batch.present? ? @batch.grading_level_list : GradingLevel.default)
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
    @student= @batch.students.last if @batch.present?
    render :pdf => "Normal Report Preview",:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end
  
  def batch_reports
    @student = Student.find params[:id]
    @batch = Batch.find params[:batch_id]
    @type = params[:report_type]
  end
  
  def students_term_reports
    if current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin?
      @is_privilaged = true
    end
    @term = AssessmentTerm.find params[:term_id]
    @plan = @term.assessment_plan
    @course = Course.find params[:course_id]
    @generated_report = @term.course_report(@course.id)
    if @is_privilaged
      @batches = @generated_report.batches.all(:conditions => { :is_deleted => false }, :include => :students, :order => 'name')
    elsif current_user.employee? and current_user.is_a_batch_tutor?
      employee = current_user.employee_record
      batch_ids = employee.batches.collect(&:id)
      @batches = @generated_report.batches.all(:conditions=>["batches.id in (?) and is_deleted = ?",batch_ids,false], :include => :students, :order => 'name')
    end
    @batch = params[:batch_id].present? ? @course.batches.find(params[:batch_id]) : @batches.try(:first)
    @is_student_report = params[:student_id].present?
    @from_manage_exam = params[:from_manage_exam].present?
    if @batch.present?
      @report_published = @generated_report.fetch_status(@batch.id)
      @students = @generated_report.fetch_students(@batch.id)
      if @is_student_report
        @student = Student.find(params[:student_id])
        @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @term.id, :reportable_type => 'AssessmentTerm'})
      end
    end
  end
  
  def student_exam_reports
    if current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin?
      @is_privilaged = true
    end
    @report = AssessmentGroup.find(params[:group_id], :include => 
        {:assessment_group_batches => [:subject_assessments, {:batch => :students}]})
    @academic_year = @report.academic_year
    @assessment_group = AssessmentGroup.find params[:group_id]
    @course = Course.find params[:course_id]
    @term = @report.parent
    @generated_report = @assessment_group.course_report(@course.id)
    if @is_privilaged
      @batches = @generated_report.batches.all(:conditions => { :is_deleted => false }, :include => :students, :order => 'name')
    elsif current_user.employee? and current_user.is_a_batch_tutor?
      employee = current_user.employee_record
      batch_ids = employee.batches.collect(&:id)
      @batches = @generated_report.batches.all(:conditions=>["batches.id in (?) and is_deleted = ?",batch_ids,false], :include => :students, :order => 'name')
    end
    @batch = params[:batch_id].present? ? @course.batches.find(params[:batch_id]) : @batches.try(:first)
    @is_student_report = params[:student_id].present?
    @from_manage_exam = params[:from_manage_exam].present?
    if @batch.present?
      @report_published = @generated_report.fetch_status(@batch.id)
      @students = @generated_report.fetch_students(@batch.id)
      if @is_student_report
        @student =  Student.find params[:student_id]
        @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @assessment_group.id, :reportable_type => 'AssessmentGroup'}) if @student.present?
      end
    end
  end
  
  def refresh_students
    @batch = Batch.find params[:batch_id]
    @students = @batch.effective_students
    @student = @students.try(:first)
    render :update do |page|
      page.replace_html 'student_report', :partial => 'report_container'
      page.replace_html 'remarks_section', :text => ''
      page.replace_html 'pdf_link', :text => ''
      page.replace_html 'student_select', :partial => 'student_select', :locals => {:exam_type => params[:exam_type], :reportable_id => params[:reportable_id]}
    end
  end
  
  def select_report
    @batch = Batch.find params[:batch_id]
    @student = Student.find params[:student_id]
    @type = params[:report_type]
    @reports = @student.get_reports(@batch.id,@type)
    render :update do |page|
      page.replace_html 'report_selector', :partial => 'report_selector'
      page.replace_html 'student_report', :partial => 'report_container'
      page.replace_html 'remarks_section', :text => ''
      page.replace_html 'pdf_link', :text => ''
    end
  end
  
  def refresh_report
    @exams = []
    if params[:reportable_id].present? and params[:student_id].present?
      @batch = Batch.find params[:batch_id]
      if params[:exam_type] == 'term_report'
        @reportable = AssessmentTerm.find params[:reportable_id]
        @exams = @reportable.assessment_groups.all(:conditions=>["type=? and is_single_mark_entry = ?","SubjectAssessmentGroup",true])
      elsif params[:exam_type] == 'plan_report'
        @reportable = AssessmentPlan.find params[:reportable_id]
        @exams = @batch.assessment_groups.all(:conditions=>["type=? and is_single_mark_entry = ?","SubjectAssessmentGroup",true],:order=>'parent_id,id')
        @terms = AssessmentTerm.find(@exams.collect(&:parent_id).uniq)
        @term_span = {}
        @terms.each do |term|
          @term_span[term.id] = @exams.select{|e| e.parent_id==term.id}.count
        end
      else
        @reportable = AssessmentGroup.find params[:reportable_id]
      end
      @generated_report = @reportable.course_report(@batch.course_id)
      grb_id = @generated_report.generated_report_batches.find_by_batch_id(@batch.id).id
      @exam_type = params[:exam_type]
      @student = Student.decide_and_find(params[:student_id])
      @schol_report = @student.individual_reports.first(:conditions => 
          {:reportable_id => @reportable.id, 
          :reportable_type => @reportable.class.table_name.classify,
          :generated_report_batch_id =>grb_id}, :include => :individual_report_pdf)
      render :update do |page|
        page.replace_html 'remarks_section', :partial => "#{params[:exam_type]}_remarks_section"
        page.replace_html 'pdf_link', :partial => 'pdf_link'
        if @schol_report.individual_report_pdf.present?
          page << "renderPdf('#{@schol_report.individual_report_pdf.attachment.url(:original, false)}', 'planner-canvas')"
        else
          page.replace_html 'student_report', :partial => "student_#{params[:exam_type]}"
        end
      end
    else
      render :update do |page|
        page.replace_html 'student_report', :partial => 'report_container'
        page.replace_html 'remarks_section', :text => "" 
        page.replace_html 'pdf_link', :text => ""
      end
    end
  end
  
  def student_term_report_pdf
    @student = Student.decide_and_find(params[:student_id])
    @term = AssessmentTerm.find params[:reportable_id]
    @exams = @term.assessment_groups.all(:conditions=>["type=? and is_single_mark_entry = ?","SubjectAssessmentGroup",true])
    @batch = Batch.find params[:batch_id]
    @student.batch_in_context_id = @batch.id
    @generated_report = @term.course_report(@batch.course_id)
    @setting = AssessmentReportSettingCopy.result_as_hash(@generated_report.id, @term.assessment_plan.id)
    #    @general_records = AssessmentReportSetting.result_as_hash @term.assessment_plan_id
    @general_records = AssessmentReportSettingCopy.result_as_hash(@generated_report.id, @term.assessment_plan_id)
    grb_id = @generated_report.generated_report_batches.find_by_batch_id(@batch.id).id
    @grade_sets = GradeSet.find_all_by_id [@general_records['ScholasticGradeScale'], @general_records['CoScholasticGradeScale']]
    @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @term.id, :reportable_type => 'AssessmentTerm', :generated_report_batch_id => grb_id})
    if @schol_report.individual_report_pdf.present?
      file = @schol_report.individual_report_pdf
#      send_file(file.attachment.path, :type => file.attachment_content_type)
      redirect_to file.attachment.url(:original, false)
    else
      render :pdf => "Student Term Report - #{@student.admission_no}",:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => { :html => nil }
    end
  end
    
  def generate_exam_reports
    @current_user = current_user
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report = AssessmentGroup.find(params[:group_id], :include => 
        {:assessment_group_batches => [:subject_assessments, {:batch => :students}]})
    @course = Course.find params[:course_id]
    @academic_year = @report.academic_year
    @term = @report.parent
    @all_batches = @course.batches_in_academic_year(@academic_year.id)
    @generated_report = (@report.course_report(@course.id)||GeneratedReport.new(:report => @report, :course_id => @course.id))
    if params[:generated_report].present?
      @generated_report.attributes = params[:generated_report]
      @generated_report.save
    end
    @batches = @generated_report.get_batches(@report, @course)
  end
  
  def send_result_publish_notification
    params[:details].each do |index, set|
      published_exam_details={}
      report_batch = GeneratedReportBatch.last(:conditions=>["batch_id=? and generated_report_id=?",set[:batch_id],set[:generated_report_id]],:include=>[:individual_reports])
      published_exam_details[:recipients] = report_batch.individual_reports.collect(&:student_id)
      published_exam_details[:exam_name] =  report_batch.generated_report.report.name
      published_exam_details[:report_batch_id] = report_batch.id   
      AutomatedMessageInitiator.gradebook_result_published(published_exam_details)
    end
    flash[:notice] = "#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}"
    render :update do |page|
      page.reload
    end
  end

  check_request_fingerprint :send_result_publish_notification
  
  def generate_term_reports
    @current_user = current_user
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report = AssessmentTerm.find(params[:term_id], :include => :assessment_groups)
    @course = Course.find params[:course_id]
    @generated_report = (@report.course_report(@course.id)||GeneratedReport.new(:report => @report, :course_id => @course.id))
    if params[:generated_report].present?
      @generated_report.attributes = params[:generated_report]
      @generated_report.save
    end
    @batches = @generated_report.get_term_batches(@course,@is_privilaged)
    @academic_year = @report.assessment_plan.academic_year
  end
  
  def regenerate_reports
    generated_report = GeneratedReport.find params[:report_id]
    report_batch = generated_report.generated_report_batches.batch_for_generation(params[:batch_id])
    if report_batch.present? and report_batch.first.update_attributes(:generation_status => 4)
      generated_report.generate_report(params[:batch_id])
    end
    if generated_report.report_type == 'AssessmentTerm'
      redirect_to :action=> 'generate_term_reports', :term_id => generated_report.report_id, :course_id => params[:course_id]
    elsif generated_report.report_type == 'AssessmentPlan'
      redirect_to :action=> 'generate_planner_reports', :assessment_plan_id => generated_report.report_id, :course_id => params[:course_id]
    else
      redirect_to :action=> 'generate_exam_reports', :group_id => generated_report.report_id, :course_id => params[:course_id]
    end
  end
  
  def student_exam_report_pdf
    @student = Student.decide_and_find(params[:student_id])
    @assessment_group = AssessmentGroup.find params[:reportable_id]
    @batch = Batch.find params[:batch_id]
    @student.batch_in_context_id = @batch.id
    @generated_report = @assessment_group.course_report(@batch.course_id)
    @general_records = AssessmentReportSettingCopy.result_as_hash(@generated_report.id,@assessment_group.assessment_plan_id)
    #    @general_records = AssessmentReportSetting.result_as_hash @assessment_group.assessment_plan_id
    grb_id = @generated_report.generated_report_batches.find_by_batch_id(@batch.id).id
    @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @assessment_group.id, :reportable_type => 'AssessmentGroup', :generated_report_batch_id => grb_id})
    if @schol_report.individual_report_pdf.present?
      file = @schol_report.individual_report_pdf
#      send_file(file.attachment.path, :type => file.attachment_content_type)
      redirect_to file.attachment.url(:original, false)
    else
      render :pdf => "Student Exam Report - #{@student.admission_no}", :margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    end
  end
  
  def publish_reports
    generated_report = GeneratedReport.find params[:report_id]
    generated_report.publish_reports(params[:course_id], params[:batch_id])
    flash[:notice] = "#{t('report_published')}"
    if generated_report.report_type == 'AssessmentTerm'
      redirect_to :action=> 'generate_term_reports', :term_id => generated_report.report_id, :course_id => params[:course_id]
    elsif generated_report.report_type == 'AssessmentPlan'
      redirect_to :action=> 'generate_planner_reports', :assessment_plan_id => generated_report.report_id, :course_id => params[:course_id]
    else
      redirect_to :action=> 'generate_exam_reports', :group_id => generated_report.report_id, :course_id => params[:course_id]
    end
  end
  
  def generate_planner_reports
    @current_user = current_user
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report = AssessmentPlan.find params[:assessment_plan_id]
    @course = Course.find params[:course_id]
    @generated_report = (@report.course_report(@course.id)||GeneratedReport.new(:report => @report, :course_id => @course.id))
    if params[:generated_report].present?
      @generated_report.attributes = params[:generated_report]
      @generated_report.save
    end
    if @is_privilaged
      @batches_in_year = @course.batches_in_academic_year(@report.academic_year_id)
    elsif @current_user.employee? and @current_user.is_a_batch_tutor? 
      employee = @current_user.employee_record
      batch_ids = employee.batches.collect(&:id)
      @batches_in_year = @course.batches_in_academic_year(@report.academic_year_id).all(:conditions=>["batches.id in (?)",batch_ids])
    end
    @batches = @generated_report.get_plan_batches(@batches_in_year,@report)
    @academic_year = @report.academic_year
  end
  
  def students_planner_reports
    if current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin?
      @is_privilaged = true
    end
    @plan = AssessmentPlan.find params[:plan_id]
    @course = Course.find params[:course_id]
    @generated_report = @plan.course_report(@course.id)
    if @is_privilaged
      @batches = @generated_report.batches.all(:conditions => { :is_deleted => false }, :include => :students, :order => 'name')
    elsif current_user.employee? and current_user.is_a_batch_tutor?
      employee = current_user.employee_record
      batch_ids = employee.batches.collect(&:id)
      @batches = @generated_report.batches.all(:conditions=>["batches.id in (?) and is_deleted = ?",batch_ids,false], :include => :students, :order => 'name')
    end
    @batch = params[:batch_id].present? ? @course.batches.find(params[:batch_id]) : @batches.try(:first)
    @is_student_report = params[:student_id].present?
    @from_manage_exam = params[:from_manage_exam].present?
    if @batch.present?
      @report_published = @generated_report.fetch_status(@batch.id)
      @students = @generated_report.fetch_students(@batch.id)
      if @is_student_report
        @student = Student.find(params[:student_id])
        @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @plan.id, :reportable_type => 'AssessmentPlan'})
      end
    end 
  end
  
  def student_plan_report_pdf
    @student = Student.decide_and_find(params[:student_id])
    @assessment_plan = AssessmentPlan.find params[:reportable_id]
    @batch = Batch.find params[:batch_id]
    @student.batch_in_context_id = @batch.id
    @generated_report = @assessment_plan.course_report(@batch.course_id)
    @general_records = AssessmentReportSettingCopy.result_as_hash(@generated_report.id,@assessment_plan.id)
    grb_id = @generated_report.generated_report_batches.find_by_batch_id(@batch.id).id
    @grade_sets = GradeSet.find_all_by_id [@general_records['ScholasticGradeScale'], @general_records['CoScholasticGradeScale']]
    @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @assessment_plan.id, :reportable_type => 'AssessmentPlan', :generated_report_batch_id => grb_id}, :include => :individual_report_pdf)
    if @schol_report.individual_report_pdf.present?
      file = @schol_report.individual_report_pdf
#      send_file(file.attachment.url(:original, false), :type => file.attachment_content_type)
      redirect_to file.attachment.url(:original, false)
    else
      render :pdf => "Student Plan Report - #{@student.admission_no}", :margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    end
  end
  
  def generate_batch_wise_reports
    batch_report = BatchWiseStudentReport.new(batch_report_params)
    if batch_report.save
      Delayed::Job.enqueue(batch_report,{:queue => "gradebook"})
    end
    redirect_to generate_planner_reports_assessment_reports_path(
      :assessment_plan_id => params[:batch_wise_report][:reportable_id],
      :course_id => params[:batch_wise_report][:course_id]
    )
  end
  
  def fetch_profiles
    instance_variable_set("@#{params[:profile_type].tableize}_grades", GradeSet.find(params[:profile_id]))
    render :partial => "report_grades", :locals => {:grade_set => instance_variable_get("@#{params[:profile_type].tableize}_grades")}
  end
  
  def fetch_templates
    if params[:template].present?
      @report_template = GradebookTemplate.get_template(params[:template])
      load_settings
      render :update do |page| 
        page.replace_html "select-template-conatiner", :partial => "selected_template"
        page.replace_html "report_cont", :partial => "student_details_settings"
      end
    else
      load_templates(params[:page],true)
      @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::SETTINGS + (@report_template.try(:settings_keys) || []), params[:plan_id]
      render :update do |page| 
        page.replace_html "select-template-conatiner", :partial => "select_template"
        page.replace_html "report_cont", :text => "<div class='no_template'>#{t('select_a_template')}</div>"
      end
    end
  end

  def general_settings
    @plan = AssessmentPlan.find_by_id(params[:plan_id])
    load_settings
    if params[:enable_custom_template] == "true"
      if @setting[:custom_template].present?
        render :partial => 'student_details_settings'
      else
        render :text => ""
      end
    else
      render :partial => "template_settings"
    end
  end
  
  def template_preview
    @report_template = GradebookTemplate.get_template(params[:template])
    render :update do |page|
      page << "build_modal_box({'title' : '#{@report_template.name.titleize}'})"
      page << "set_popup_width_template_preview()"
      page.replace_html 'popup_content', :partial => 'preview_template'
    end
  end
  
  def preview_img
    path = params[:name].present? ? (Rails.root.join(URI.encode("vendor/plugins/gradebook_templates/#{params[:name]}/assets/preview.png"))) : ""
    send_file(path)
  end
  
  private
  
  def batch_report_params
    parameters = {
      :report_type => params[:batch_wise_report][:report_type],
      :batch_ids => params[:batch_wise_report][:batch_ids],
      :reportable_id => params[:batch_wise_report][:reportable_id]
    }
    
    {:parameters => parameters, :is_gradebook => true, :status => 'in queue', :course_id => params[:batch_wise_report][:course_id]}
  end
  
  def get_frequency
    if @setting[:frequency] == "0"
      "AssessmentGroup"
    elsif @setting[:frequency] == "1"
      "AssessmentTerm"
    else
      "AssessmentPlan"
    end
  end
  
  def get_record_settings
    options = AssessmentReportSetting::STUDENT_RECORD_SETTINGS + AssessmentReportSetting::MAIN_REMARK_SETTINGS + 
      AssessmentReportSetting::SUB_REMARK_SETTINGS + AssessmentReportSetting::REMARK_INHERIT_SETTINGS
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash options, @plan.id
    @type = params[:frequency].present? ? params[:frequency]:get_frequency
    #    @plan.build_record_groups
    @disable = false
    @plan.gradebook_record_groups.each{|grg| @disable = true if grg.gradebook_records.count != 0}
    @remark_sets_hash = @plan.build_or_get_remark_sets
    @remark_sets = @remark_sets_hash[:remark_sets]
  end
  
  def load_templates(page = 1, go_back = false)
    @report_templates = GradebookTemplate.available_templates.paginate(:per_page => 3, :page => page)
    template_setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::CUSTOM_TEMPLATE_KEYS, @plan.id
    if template_setting[:enable_custom_template] == '1' and !go_back
      @report_template = @plan.report_template
    end
  end
  
  def load_settings
    @setting = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::SETTINGS + (@report_template.try(:settings_keys) || []), params[:plan_id]
    @student_fields = AssessmentReportSetting::SETTINGS_WITH_VALUES
    @student_additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
  end
  
end








