class GradebookRemarksController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :attribute_check=>true, :load_method => lambda {Course.find(params[:id])}
  require 'lib/override_errors'
  helper OverrideErrors
  
  def manage
    @course = Course.find_by_id(params[:id], :include => :assessment_plans)
    @academic_year = AcademicYear.find_by_id(params[:academic_year_id])
    fetch_batches_wrt_privilege
    @assessment_plan = @course.assessment_plans.compact.select{|ap| ap.academic_year_id == @academic_year.id}
    @report_types = []; @remark_types = []; @reportables = []; @remarkables = [];
  end
  
  def update_remark_type
    @course = Course.find_by_id(params[:id])
    @assessment_plan = AssessmentPlan.find_by_id(params[:assessment_plan_id], :include => :assessment_report_settings)
    @remark_types = params[:batch_id].present? ? @assessment_plan.get_remark_types(@course,params[:batch_id]) : []
    @reportables = []; @remarkables = []; @report_types = [];
    render :update do |page|
      page.replace_html 'remark_type_select_container', :partial => 'remark_type_select'
      page.replace_html 'report_type_select_container', :partial => 'report_type_select'
      page.replace_html 'reportable_select_container', :partial => 'reportable_select'
      page.replace_html 'flash-container', :text => ''
      page.replace_html 'remarkable_select_container', :text => ''
      page.replace_html 'remark_sets_or_subjects', :text => ''
      page.replace_html 'student_list', :text => ''
    end
  end
  
  def update_report_type
    @assessment_plan = AssessmentPlan.find_by_id(params[:assessment_plan_id], :include => :assessment_report_settings)
    @report_types = params[:remark_type].present? ? @assessment_plan.get_report_types(params[:remark_type]) : []
    @reportables = []; @remarkables = [];
    render :update do |page|
      page.replace_html 'report_type_select_container', :partial => 'report_type_select'
      page.replace_html 'reportable_select_container', :partial => 'reportable_select'
      page.replace_html 'flash-container', :text => ''
      page.replace_html 'remarkable_select_container', :text => ''
      page.replace_html 'remark_sets_or_subjects', :text => ''
      page.replace_html 'student_list', :text => ''
    end
  end
  
  def update_reportable
    @batch = Batch.find_by_id(params[:batch_id])
    @assessment_plan = AssessmentPlan.find_by_id(params[:assessment_plan_id])
    if params[:report_type] == "AssessmentGroup"
      @reportables = @batch.assessment_groups.select{|ag| ag.type == "SubjectAssessmentGroup"}
    elsif params[:report_type] == "AssessmentTerm"
      @reportables = @assessment_plan.assessment_terms
    else
      @reportables = params[:report_type].present? ? [@assessment_plan] : []
    end
    @remarkables = [];
    render :update do |page|
      page.replace_html 'reportable_select_container', :partial => 'reportable_select'
      page.replace_html 'flash-container', :text => ''
      page.replace_html 'remarkable_select_container', :text => ''
      page.replace_html 'remark_sets_or_subjects', :text => ''
      page.replace_html 'student_list', :text => ''
    end
  end
  
  def update_remarkable
    if params[:reportable_id].present?
      @course = Course.find_by_id(params[:id])
      @batch = Batch.find_by_id(params[:batch_id])
      @remark_type = params[:remark_type]
      if params[:remark_type] == "RemarkSet"
        @remarkables = RemarkSet.find_all_by_assessment_plan_id_and_target_type(params[:assessment_plan_id],params[:report_type])
      else
        fetch_subjects_wrt_privilege
      end
      @plan_id = params[:assessment_plan_id] unless @remarkables.present?
      render :update do |page|
        page.replace_html 'flash-container', :partial => 'flash_message' unless @remarkables.present?
        page.replace_html 'remarkable_select_container', :partial => 'remarkable_select'
        page.replace_html 'remark_sets_or_subjects', :text => ''
        page.replace_html 'student_list', :text => ''
      end
    else
      render :update do |page|
        page.replace_html 'flash-container', :text => ''
        page.replace_html 'remarkable_select_container', :text => ''
        page.replace_html 'remark_sets_or_subjects', :text => ''
        page.replace_html 'student_list', :text => ''
      end
    end
  end
  
  def update_student_list
    if params[:remarkable_id].present?
      @batch = Batch.find_by_id(params[:batch_id])
      get_remarkable_and_students
      build_gradebook_remark(@batch, params[:report_type], params[:reportable_id],
        params[:remark_type], params[:remarkable_id])
      render :update do |page|
        page.replace_html 'remark_sets_or_subjects', :partial => 'remark_sets_or_subjects' if @students.present?
        page.replace_html 'student_list', :partial => 'student_list' if @students.present?
        page.replace_html 'flash-container', :partial => 'flash_message' unless @students.present?
      end
    else
      render :update do |page|
        page.replace_html 'remark_sets_or_subjects', :text => ''
        page.replace_html 'student_list', :text => ''
        page.replace_html 'flash-container', :text => ''
      end
    end
  end
    
  def update_remark
    gradebook_remark = GradebookRemark.find_by_student_id_and_batch_id_and_reportable_type_and_reportable_id_and_remarkable_type_and_remarkable_id(params[:gradebook_remark][:student_id],
      params[:gradebook_remark][:batch_id],params[:gradebook_remark][:reportable_type],
      params[:gradebook_remark][:reportable_id],params[:gradebook_remark][:remarkable_type],
      params[:gradebook_remark][:remarkable_id])
    unless gradebook_remark.present?
      gradebook_remark = GradebookRemark.new(params[:gradebook_remark])
      status = gradebook_remark.save ? true : false
    else
      status = gradebook_remark.update_attributes(params[:gradebook_remark]) ? true : false
    end
    render :json => {:status => status}
  end
  
  def add_from_remark_bank
    @remark_banks = RemarkBank.all
    @student_id = params[:student_id]
    render :update do |page|
      page << "build_modal_box({'title' : 'Select from Remark Bank'})" 
      page.replace_html 'popup_content', :partial => 'add_from_remark_bank'
    end
  end
  
  def update_remark_templates
    if params[:remark_bank_id].present?
      remark_bank = RemarkBank.find_by_id(params[:remark_bank_id])
      @student_id = params[:student_id]
      @remark_templates = remark_bank.remark_templates
      render :update do |page|
        page.replace_html 'remark-templates', :partial => 'remark_templates'
      end
    else
      render :update do |page|
        page.replace_html 'remark-templates', :text => ''
        page.replace_html 'app', :text => ''
        page.replace_html 'popup_footer', :text => ''
      end
    end
  end
  
  def update_remark_preview
    @remark_templates = RemarkTemplate.find_all_by_id(params[:remark_template_ids])
    @student = Student.find_by_id(params[:student_id])
    @keys = RemarkTemplate.get_keys
    render :update do |page|
      page.replace_html 'app', :partial => 'update_remark_preview'
    end
  end
  
  private
  
  def build_gradebook_remark(batch, reportable_type,reportable_id, remarkable_type, remarkable_id)
    if @students.present?
      @remarks = []
      @students_hash = Hash.new
      @number = Configuration.enabled_roll_number? 
      @students.each do |s|
        @students_hash[s.id] = "#{s.full_name}<br>(#{Configuration.enabled_roll_number? ? s.roll_number : s.admission_no})"
        @remarks << GradebookRemark.find_or_initialize_by_student_id_and_batch_id_and_reportable_type_and_reportable_id_and_remarkable_type_and_remarkable_id(s.id, 
          batch.id, reportable_type, reportable_id,remarkable_type, remarkable_id)
      end
    end
  end
  
  def get_remarkable_and_students
    if params[:remark_type] == 'Subject'
      @remarkable = Subject.find_by_id(params[:remarkable_id])
      @students = @remarkable.fetch_students.paginate(:per_page => 10, :page => params[:page])
    else
      @remarkable = RemarkSet.find_by_id(params[:remarkable_id])
      @students = @batch.effective_students.paginate(:per_page => 10, :page => params[:page])
    end
  end
  
  def fetch_batches_wrt_privilege
    employee = @current_user.employee_entry
    @subject_ids = employee.present? ? employee.subjects.collect(&:id) : []
    if has_main_gradebook_privileges
      @batches = @course.batches_in_academic_year(@academic_year.id)
    else
      @batches = []
      if @current_user.employee? and @course.is_tutor_and_has_batch_in_this_course_academic_year(@academic_year.id)
        batch_ids = employee.batches.collect(&:id)
        @batches = @course.batches.find(:all,:conditions=>["batches.id in (?) and academic_year_id = ?",batch_ids,@academic_year.id])
      end
      if @current_user.employee? and @course.is_subject_teacher_and_has_batch_in_this_course
        @batches += Batch.all(:joins=>:subjects,:conditions=>["subjects.id in (?) and course_id = ? and academic_year_id = ?",@subject_ids,@course.id,@academic_year.id],:group=>'batches.id')
      end
      @batches = @batches.uniq
    end
  end
  
  def fetch_subjects_wrt_privilege
    employee = @current_user.employee_entry
    if has_main_gradebook_privileges or (@current_user.employee? and @course.is_tutor_and_has_batch_in_this_course_academic_year(@batch.academic_year.id))
        @remarkables = @batch.subjects
    else
      if @current_user.employee? and @course.is_subject_teacher_and_has_batch_in_this_course
        @remarkables = employee.subjects.select{|sub| sub.batch_id == @batch.id} if employee.present?
      end
    end
  end
  
  def has_main_gradebook_privileges
    @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin? or @current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))
  end
  
end
