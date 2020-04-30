class AssessmentsController < ApplicationController
  before_filter :login_required
  before_filter :validate_application_sms_setting, :only => [:notification_group_selector, :send_notification]
  filter_access_to :all, :except=>[:show,:subject_scores,:manage_derived_assessment,:calculate_derived_marks]
  filter_access_to :show, :attribute_check=>true, :load_method => lambda { Course.find(params[:course_id]) }
  filter_access_to :subject_scores, :attribute_check=>true, :load_method => lambda { SubjectAssessment.find(params[:id]).assessment_group_batch.batch }
  filter_access_to :skill_scores, :attribute_check=>true, :load_method => lambda { SubjectAssessment.find(params[:assessment_id]).assessment_group_batch.batch }
  filter_access_to :manage_derived_assessment, :attribute_check=>true, :load_method => lambda { Course.find(params[:course_id]) }
  filter_access_to :calculate_derived_marks, :attribute_check=>true, :load_method => lambda { Batch.find params[:batch_id] }
  require 'lib/override_errors'
  helper OverrideErrors
  
  def show
    @assessment_group = AssessmentGroup.find params[:id]
    @course = Course.find(params[:course_id])
    @academic_year = @assessment_group.academic_year #AcademicYear.find params[:academic_year_id]
    @type = @assessment_group.exam_type
    batch_ids = @course.batches_in_academic_year(@academic_year.id).active.collect(&:id).uniq
    employee = @current_user.employee_entry
    @subject_ids = employee.present? ? employee.subjects.collect(&:id) : []
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin? or @current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))
      @all_batches = @course.batches_in_academic_year(@academic_year.id)
      @privileged = true
    else
      @all_batches = []
      if @current_user.is_a_batch_tutor? 
        batch_ids = employee.batches.collect(&:id)
        @all_batches = @course.batches.find(:all,:conditions=>["batches.id in (?) and academic_year_id = ?",batch_ids,@academic_year.id])
      end
      if @current_user.has_assigned_subjects?
        @all_batches += Batch.all(:joins=>:subjects,:conditions=>["subjects.id in (?) and course_id = ? and academic_year_id = ?",@subject_ids,@course.id,@academic_year.id],:group=>'batches.id')
      end
    end
    @all_batches = @all_batches.uniq
    show_import(@type)
    @assessments = @assessment_group.fetch_batch_assessments(@all_batches.collect(&:id).uniq)
    @all_activated =  (batch_ids - @assessments.keys).blank?
    @assess_active = @assessments.present?
    @inactive_subjects = @assessment_group.fetch_inactive_assessments(batch_ids)
    flash[:notice] = t('assessments_unlocked') if params[:unlocked].present?
  end
  
  def notification_group_selector
    @assessment_group = AssessmentGroup.find(params[:assessment_group_id], :include=>{:assessment_group_batches=>[:batch]})
    @batches = @assessment_group.assessment_group_batches.collect{|g| g.batch }
    @batch = params[:batch_id]
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('notification')}'})"
      page.replace_html 'popup_content', :partial => 'notification_group_selector'
    end
  end
  
  def send_notification  
    ag = AssessmentGroup.find params[:notification][:assessment_group_id] 
    batch_ids = params[:notification][:batch]
    batches = Batch.all(:conditions=>["id in (?)",batch_ids],:include=>[:students])
    if batches.present? && ag.present?
      flash[:notice] ="#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}"
      batches.each do |batch| 
        scheduled_exam_details = AssessmentGroupBatch.build_sms_details(batch,ag)
        AutomatedMessageInitiator.gradebook_schedule_exams(scheduled_exam_details)
      end
    end
    redirect_to :back , :params => params 
  end

  check_request_fingerprint :send_notification
  
  def link_attributes
    @batch = Batch.find params[:batch_id]
    @course = @batch.course
    @assessment_group = AssessmentGroup.find params[:assessment_group_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    if @batch.is_active?
      @subjects = @batch.all_normal_subjects
      @attribute_profiles = AssessmentAttributeProfile.all(:select=>'DISTINCT assessment_attribute_profiles.*',:joins=>:assessment_attributes)
      @assessment_group_batch = @assessment_group.assessment_group_batches.find_or_initialize_by_batch_id(@batch.id, 
        :include => {:subject_attribute_assessments => :assessment_attribute_profile})
      @subjects_with_marks = @assessment_group_batch.subjects_with_marks
      if request.post? or request.put?
        @assessment_group_batch.update_attributes(params[:assessment_group_batch])
        flash[:notice] = t('exams_activated_for_selected_batches')
        redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id, :academic_year_id => @academic_year.id
      else
        @assessment_group_batch.build_attribute_assessments(@subjects)
      end
    else
      flash[:notice] = t('flash_msg4')
      redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id, :academic_year_id => @academic_year.id
    end
  end
  
  def update_profile_info
    profile = AssessmentAttributeProfile.find params[:id]
    render :json => {'attributes' => profile.assessment_attributes.count, 'formula' => profile.formula.capitalize, 'max_marks' => profile.maximum_marks}
  end
  
  def activate_exam
    @course = Course.find params[:course_id]
    find_assessment_group
    @batches =  if @assessment_group.subject_assessment?
      @course.batches_in_academic_year_with_subject(@assessment_group.academic_year_id)
    else
      @course.batches_in_academic_year(@assessment_group.academic_year_id)
    end
    @assessments = @assessment_group.fetch_batch_assessments @batches.collect(&:id).uniq
    @batches.reject! {|batch| @assessments.keys.include?(batch.id)}
    if request.post?
      batch_ids = params[:batch_ids]
      if batch_ids.present?
        @assessment_group.create_assessments(batch_ids,@course)
        flash[:notice] = t('exams_activated_for_selected_batches')
      else
        flash[:notice] = t('assessment_not_activated')
      end
      redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id, :academic_year_id => @academic_year.id
    end
  end
  
  def activate_subject
    find_assessment_group
    batch = Batch.find params[:batch_id]
    subject = Subject.find params[:subject_id]
    assessment = @assessment_group.insert_subject_attribute_assessments(batch.id, subject, @type)
    flash[:notice] = (assessment ? t('exams_activated_for_subject', {:sub_name => subject.name}) : t('exams_not_activated_for_subject', {:sub_name => subject.name}))
    redirect_to :action => :show, :id => @assessment_group.id, :course_id => batch.course_id, :academic_year_id => @academic_year.id
  end

  def schedule_dates
    @assessment_group = AssessmentGroup.find params[:id]
    @course = Course.find params[:course_id]
    @batches = AssessmentSchedule.fetch_batches(@assessment_group, @course)
    @academic_year = @assessment_group.academic_year
    @assessment_schedule = AssessmentSchedule.new(:assessment_group_id => @assessment_group.id, :course_id => @course.id)
  end
  
  def edit_dates
    fetch_data
    @batches = AssessmentSchedule.fetch_batches(@assessment_group, @course, @assessment_schedule.id)
    @assessment_schedule.set_timings
    render :schedule_dates
  end
  
  def save_schedule
    @assessment_schedule = (params[:schedule_id].present? ? AssessmentSchedule.find(params[:id]) : AssessmentSchedule.new(params[:assessment_schedule]))
    if (params[:id].present? ? @assessment_schedule.update_attributes(params[:assessment_schedule]) : @assessment_schedule.save)
      flash[:notice] = t('flash1')
      redirect_to :action => :new, :id => params[:group_id], :schedule_id => @assessment_schedule.id
    else
      @assessment_group = AssessmentGroup.find params[:group_id]
      @course = Course.find params[:course_id]
      @batches = AssessmentSchedule.fetch_batches(@assessment_group, @course)
      @academic_year = @assessment_group.academic_year
      render :schedule_dates
    end
  end
  
  def new
    fetch_data
    @batches = @assessment_schedule.batches.all(:include => [:course, :subjects])
    @assessment_form = AssessmentForm.build_form(@assessment_schedule, @assessment_group, @batches)
    @subjects = AssessmentForm.fetch_subjects(@batches)
  end
  
  def create
    @assessment_form = AssessmentForm.new(params[:assessment_form])
    assessment_group = AssessmentGroup.find(params[:assessment_form][:assessment_group_id])
    fetch_data
    if @assessment_form.valid?
      @assessment_form.save_assessments(@assessment_schedule)
      if params[:commit] == "Save and Send Notification"
        flash[:notice] = t('exam_notification_sent') 
        @assessment_schedule.batches.each do |batch|
          scheduled_exam_details = AssessmentGroupBatch.build_sms_details(batch,assessment_group)
          AutomatedMessageInitiator.gradebook_schedule_exams(scheduled_exam_details)
        end
      end
      redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id, :academic_year_id => @academic_year.id
    else
      @batches = @assessment_schedule.batches.all(:include => [:course, :subjects])
      @subjects = AssessmentForm.fetch_subjects(@batches)
      render :new
    end
  end
  
  def edit
    @assessment_group = AssessmentGroup.find params[:id]
    @batch = Batch.find(params[:batch_id])
    @course = @batch.course
    @batches = @course.batches_in_academic_year(@assessment_group.academic_year_id)
    @assessment_schedule = @batch.assessment_schedules.first(:conditions => {:assessment_group_id => @assessment_group.id})
    @group_batch = AssessmentGroupBatch.first(:conditions => {:assessment_group_id => @assessment_group.id, :batch_id => @batch.id})
    @academic_year = AcademicYear.find(params[:academic_year_id])
    @subjects = AssessmentForm.fetch_batch_subjects(@batch)
    @assessment_marks = AssessmentGroupBatch.batch_subject_assessments_with_marks(@batch, @assessment_group)
  end
  
  def update
    @group_batch = AssessmentGroupBatch.find(params[:id])
    @assessment_group = @group_batch.assessment_group
    @batch = @group_batch.batch
    @course = @batch.course
    if @group_batch.update_attributes(params[:assessment_group_batch])
      if params[:commit] == "Save and Send Notification"
        flash[:notice] = t('exam_notification_sent') 
        scheduled_exam_details = AssessmentGroupBatch.build_sms_details(@batch,@assessment_group)
        AutomatedMessageInitiator.gradebook_schedule_exams(scheduled_exam_details)
      end
      redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id, :academic_year_id => params[:academic_year_id]
    else
      @assessment_schedule = AssessmentSchedule.find(params[:schedule_id])
      @academic_year = AcademicYear.find(params[:academic_year_id])
      @subjects = AssessmentForm.fetch_batch_subjects(@batch)
      render :edit
    end
  end
  
  def skill_scores
    fetch_action_details
    assessment_mark_include = {:assessment_marks => {:assessment => {:subject_assessment => :assessment_group_batch}}}
    @assessment = SubjectAssessment.find(params[:assessment_id], 
      :include => [:subject, {:skill_assessments => [assessment_mark_include, :subject_skill, {:sub_skill_assessments => assessment_mark_include} ]}])
    @subject = @assessment.subject
    fetch_students
    grade_set = @assessment_group.grade_set
    @grades = grade_set.try(:grades)
    @mark_entry_locked = false
    mark_entry_last_date = @agb.mark_entry_last_date.present? ? @agb.mark_entry_last_date : Date.today+1
    @mark_entry_locked = ((mark_entry_last_date<Date.today or @assessment.mark_entry_locked) and !@assessment.unlocked) || (@assessment.submission_status == 2)
    @grades_json = grade_set.try(:grades_json)
    
    if request.put? or request.post?
      @assessment.update_attributes(params[:subject_skill_assessment])
      if params[:save_and_submit_marks].present?
        if @assessment.submit_skill_marks(@students)
          marks_submitted
          lock_subject_assessment(@assessment)
        else
          flash.now[:notice] = t('please_enter_marks_for_all_students')
        end
      else
        flash.now[:notice] = t('scores_saved')
      end
    end
    
    @scores = @assessment.fetch_skill_scores
  end
  
  def attribute_scores
    fetch_action_details
    @assessment = SubjectAttributeAssessment.find(params[:assessment_id], 
      :include => [:subject, {:attribute_assessments => [{:assessment_marks => {:assessment => {:subject_attribute_assessment => :assessment_group_batch}}}, :assessment_attribute]}])
    @subject = @assessment.subject
    fetch_students
    @profile = @assessment.assessment_attribute_profile
    #@formula = @profile.formula
    @formula = (@profile.formula == 'bestof')? 'Best of' : @profile.formula
    @grades = @assessment_group.grade_set.grades_json if (@assessment_group.scoring_type == 3)
    @mark_entry_locked = false
    @mark_entry_locked = ((@assessment.mark_entry_locked) and !@assessment.unlocked) || (@assessment.submission_status == 2)
    if request.put? or request.post?
      @assessment.save_nested if @assessment.update_attributes(params[:subject_attribute_assessment])
      if params[:save_and_submit_marks].present?
        if @assessment.submit_marks(@students)
          marks_submitted
          lock_subject_assessment(@assessment)
        else
          flash.now[:notice] = t('please_enter_marks_for_all_students')
        end
      else
        flash.now[:notice] = t('scores_saved')
      end
    end
    @scores = @assessment.fetch_attribute_scores
  end
  
  def activity_scores
    fetch_action_details
    @students = @batch.effective_students
    @activity_assessment = ActivityAssessment.find(params[:assessment_id], :include => {:assessment_marks => {:assessment => :assessment_group_batch}})
    @grades = @assessment_group.grade_set.grades
    @mark_entry_locked = false
    @mark_entry_locked = ((@activity_assessment.mark_entry_locked) and !@activity_assessment.unlocked) || (@activity_assessment.submission_status == 2)
    if request.put? or request.post?
      @activity_assessment.update_attributes(params[:activity_assessment])
      if params[:save_and_submit_marks].present?
        if @activity_assessment.submit_marks(@students)
          marks_submitted
          lock_subject_assessment(@activity_assessment)
        else
          flash.now[:notice] = t('please_enter_marks_for_all_students')
          @students_scores = @activity_assessment.build_student_marks(@students)
        end
      else
        @students_scores = @activity_assessment.build_student_marks(@students)
        flash.now[:notice] = t('scores_saved')
      end
    else
      @students_scores = @activity_assessment.build_student_marks(@students)
    end
  end
  
  def subject_scores
    @assessment = SubjectAssessment.find(params[:id], :include => {:assessment_marks => {:assessment => :assessment_group_batch}})
    fetch_header_details
    if @subject.is_activity? and !@grades.present?
      flash[:notice] = "#{t('set_up_default_grade_set')}"
      redirect_to :controller=>:grading_profiles ,:action=>:index and return
    end
    @mark_entry_locked = false
    mark_entry_last_date = @agb.mark_entry_last_date.present? ? @agb.mark_entry_last_date : Date.today+1
    @mark_entry_locked = ((mark_entry_last_date<Date.today or @assessment.mark_entry_locked) and !@assessment.unlocked) || (@assessment.submission_status == 2)
    if request.put? or request.post?
      @assessment.update_attributes(params[:subject_assessment])
      if params[:save_and_submit_marks].present?
        if @assessment.submit_marks(@students)
          lock_subject_assessment(@assessment)
          marks_submitted
        else
          flash.now[:notice] = t('please_enter_marks_for_all_students') unless @mark_entry_locked
          @assessment_marks = @assessment.build_student_marks(@students,@mark_entry_locked)
        end
      else
        @assessment_marks = @assessment.build_student_marks(@students,@mark_entry_locked)
        flash.now[:notice] = t('scores_saved')
      end
    else
      @assessment_marks = @assessment.build_student_marks(@students,@mark_entry_locked)
    end
  end
  
  def unlock_assessments
    @batch = Batch.find params[:batch_id]
    @agb = AssessmentGroupBatch.all(:conditions=>['batch_id=? and assessment_group_id=?',params[:batch_id],params[:assessment_group_id]]).first
    if @agb.assessment_group.exam_type.subject_attribute or @agb.assessment_group.exam_type.subject_wise_attribute
      @subject_assessments = @agb.subject_attribute_assessments.all(:include => :subject)
    elsif @agb.assessment_group.exam_type.subject
      @subject_assessments = @agb.subject_assessments.all(:include => :subject, :order=>'exam_date,start_time')
    elsif @agb.assessment_group.exam_type.activity
      @subject_assessments = @agb.activity_assessments.all(:include=>:assessment_activity)
    end
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('change_subject_status')}', 'popup_class' : 'popup_unlock_subjects'})"
      page.replace_html 'popup_content', :partial => 'batch_subject_list'
    end
  end
  
  def unlock_subjects
    @agb = AssessmentGroupBatch.find(params[:agb], :include => [:batch,:assessment_group])
    if @agb.assessment_group.exam_type.subject_attribute or @agb.assessment_group.exam_type.subject_wise_attribute
      @subject_assessments = SubjectAttributeAssessment.all(:conditions=>["assessment_group_batch_id=? and subject_id in (?)",params[:agb],params[:subject_list]])
    elsif @agb.assessment_group.exam_type.subject
      @subject_assessments = SubjectAssessment.all(:conditions=>["assessment_group_batch_id=? and subject_id in (?)",params[:agb],params[:subject_list]])
    else
      @subject_assessments = ActivityAssessment.all(:conditions=>["assessment_group_batch_id=? and assessment_activity_id in (?)",params[:agb],params[:subject_list]])
    end
    @subject_assessments.each do |sa|
      sa.attributes = {:mark_entry_locked => false, :unlocked => true, :submission_status => nil}
      sa.send(:update_without_callbacks)
      #      sa.update_attributes(:mark_entry_locked=>false,:unlocked=>true,:submission_status=>nil)
    end
    @agb.marks_added = false
    @agb.send(:update_without_callbacks)
    #    @agb.update_attribute('marks_added',false)
    render :update do |page|
      flash[:notice] = t('assessments_unlocked') if params[:subject_list].present?
      page.redirect_to :action => 'show', :id => @agb.assessment_group_id, :academic_year_id => @agb.batch.academic_year_id, :course_id => @agb.batch.course_id
      #      page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('assessments_unlocked')} </p>" if params[:subject_list].present?
    end
  end
  
  def exam_timings
    @courses = Course.active.all(:joins => {:assessment_group_batches => :subject_assessments}, :group => "id")
    @course = Course.find params[:course_id]
    @assessment_groups = AssessmentGroupBatch.course_assessment_groups(@course.id)
    @assessment_group = AssessmentGroup.find params[:group_id]
    @term=@assessment_group.parent
    @batches = AssessmentGroupBatch.assessment_group_batches(@assessment_group.id, @course.id)
    @assessments = AssessmentGroupBatch.course_assessments(@assessment_group.id, @course.id).group_by(&:batch)
  end
  
  def exam_timings_pdf
    @data_hash = AssessmentGroupBatch.fetch_exam_timings_data(params)
    render :pdf => 'exam_timings_pdf'
  end
  
  def fetch_groups
    @course = Course.find params[:course_id]
    @assessment_groups = AssessmentGroupBatch.course_assessment_groups(@course.id)
    if request.xhr?
      render :update do |page|
        page.replace_html 'groups_list', :partial=> 'groups_list'
        page.replace_html 'batches_list', :partial=> 'batches_list'
      end
    end
  end
  
  def fetch_batches
    @course = Course.find params[:course_id]
    @assessment_group = AssessmentGroup.find params[:group_id]
    @batches = AssessmentGroupBatch.assessment_group_batches(@assessment_group.id, @course.id)
    if request.xhr?
      render :update do |page|
        page.replace_html 'batches_list', :partial=> 'batches_list'
      end
    end
  end
  
  def fetch_timetables
    @course = Course.find params[:course_id]
    @assessment_group = AssessmentGroup.find params[:group_id]
    @term=@assessment_group.parent
    @assessments = AssessmentGroupBatch.course_assessments(@assessment_group.id, @course.id)
    unless params[:batch_id] == "All" 
      @assessments = @assessments.batch_equals(params[:batch_id]) 
      @batch = Batch.find(params[:batch_id]) 
    end
    @assessments = @assessments.group_by(&:batch)
    if request.xhr?
      render :update do |page|
        page.replace_html 'exam_timetables', :partial=> 'exam_timetables'
      end
    end
  end
  
  def reset_assessments
    @assessment_group = AssessmentGroup.find params[:assessment_group_id]
    @batch = Batch.find params[:batch_id]
    @agb = @assessment_group.assessment_group_batches.first(:conditions=>{:batch_id => @batch.id})
    if @agb
      @assessment_group.delete_schedules(@agb.course_id, @batch.id) if @agb.destroy
      flash[:notice] = t('exam_deleted')
    else
      flash[:notice] = t('exam_missing')
    end
  end
  
  def manage_derived_assessment
    @assessment_group = DerivedAssessmentGroup.find params[:id]
    @course = Course.find params[:course_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin? or @current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))
      @batches = @course.batches_in_academic_year(@academic_year.id)
    elsif @current_user.is_a_batch_tutor? 
      employee = @current_user.employee_entry
      batch_ids = employee.batches.collect(&:id)
      @batches = @course.batches.find(:all,:conditions=>["batches.id in (?) and academic_year_id = ?",batch_ids,@academic_year.id])
    end
    @subject_hash = @assessment_group.get_subject_list(@batches.collect(&:id).uniq)
    @assessments = @assessment_group.fetch_batch_assessments(@batches.collect(&:id).uniq)
    @assess_active = @assessments.present?
    @batches = @assessment_group.get_submitted_batches(@course,@current_user)
  end
  
  def calculate_derived_marks
    @assessment_group = DerivedAssessmentGroup.find params[:assessment_id]
    batch = Batch.find params[:batch_id]
    @assessment_group.calculate_derived_marks(batch.id)
    redirect_to :action=> 'manage_derived_assessment', :id => @assessment_group.id, :course_id => batch.course_id, :academic_year_id => @assessment_group.academic_year_id
  end
  
  def show_derived_mark
    @course = Course.find params[:course_id]
    @batch = Batch.find params[:batch_id]
    @subject = Subject.find params[:sub_id]
    @academic_year = AcademicYear.find params[:academic_year_id]
    @assessment_group = DerivedAssessmentGroup.find params[:ag_id]
    @assessment_marks = @assessment_group.build_derived_marks(params[:batch_id],params[:sub_id])
  end
  
  private
  
  
  def fetch_data
    @assessment_schedule = AssessmentSchedule.find(params[:schedule_id]||params[:id])
    @assessment_group = @assessment_schedule.assessment_group
    @course = @assessment_schedule.course
    @academic_year = @assessment_group.academic_year
  end
  
  def fetch_action_details
    @batch = Batch.find params[:batch_id]
    @course = @batch.course
    find_assessment_group
    @agb = @assessment_group.assessment_group_batches.first(:conditions=>{:batch_id => @batch.id})
  end
  
  def find_assessment_group
    @assessment_group = AssessmentGroup.find params[:assessment_group_id]
    @academic_year = @assessment_group.academic_year
    @type = @assessment_group.exam_type
  end
  
  def fetch_header_details
    @subject = @assessment.subject
    @agb = @assessment.assessment_group_batch
    @batch = @agb.batch
    @assessment_group = @agb.assessment_group
    @academic_year = @assessment_group.academic_year
    @type = @assessment_group.exam_type
    fetch_students
    @course = @batch.course
    @grade_set = @assessment_group.grade_set
    @grade_set ||= GradeSet.default if @subject.is_activity
    @grades = @grade_set.try(:grades)
  end
  
  def fetch_students
    @students = @subject.fetch_gradebook_students
  end
  
  def marks_submitted
    redirect_to :action => :show, :id => @assessment_group.id, :course_id => @course.id
  end
  
  def lock_subject_assessment(assessment)
    assessment.update_attributes(:mark_entry_locked=>true,:unlocked=>false)
  end
  
  def show_import(type)
    agbs = @assessment_group.assessment_group_batches.all(:conditions=>["batch_id in (?) and (mark_entry_last_date >= ? or mark_entry_last_date is null)",@all_batches.collect(&:id),Date.today]).group_by(&:batch_id)#last date not passed.
    all_unlocked = {}
    all_not_submitted = {}
    @show_import = {}
    assessment_group_batches = @assessment_group.assessment_group_batches.all(:conditions=>["batch_id in (?)",@all_batches.collect(&:id)])
    assessment_group_batches.each do |agb|
      if type.subject
        all_assessments = agb.subject_assessments.count
        not_submitted_assessments = agb.subject_assessments.all(:conditions=>["submission_status is null"]).count
        all_unlocked_assessments = agb.subject_assessments.all(:conditions=>["unlocked=?",true]).count
      elsif type.subject_attribute or type.subject_wise_attribute
        all_assessments = agb.subject_attribute_assessments.count
        not_submitted_assessments = agb.subject_attribute_assessments.all(:conditions=>["submission_status is null"]).count
        all_unlocked_assessments = agb.subject_attribute_assessments.all(:conditions=>["unlocked=?",true]).count
      elsif type.activity
        all_assessments = agb.activity_assessments.count
        not_submitted_assessments = agb.activity_assessments.all(:conditions=>["submission_status is null"]).count
        all_unlocked_assessments = agb.activity_assessments.all(:conditions=>["unlocked=?",true]).count
      end
      all_not_submitted[agb.batch_id] = false
      all_unlocked[agb.batch_id] = false
      if all_assessments == not_submitted_assessments
        all_not_submitted[agb.batch_id] = true
      end
      if all_assessments == all_unlocked_assessments
        all_unlocked[agb.batch_id] = true
      end
    end
    @all_batches.each do |batch|
      @show_import[batch.id] = ((agbs[batch.id].present? and all_not_submitted[batch.id]) or all_unlocked[batch.id])
    end
    @show_import
  end
  
  def exam_schedule_sms_initiate
    sms_details = build_sms_details(batch, ag)
  end
  
end
