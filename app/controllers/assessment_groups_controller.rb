class AssessmentGroupsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  before_filter :fetch_courses, :only => [:new_course_exam, :create_course_exam]
  
  check_request_fingerprint :create, :update
  
  
  def new
    parent = params[:parent_type].constantize.find(params[:parent_id])
    @plan = (params[:parent_type] == 'AssessmentPlan' ? parent : parent.assessment_plan)
    @term = parent unless params[:parent_type] == 'AssessmentPlan'
    @assessment_group = SubjectAssessmentGroup.new(:parent => parent, :scoring_type => 1, :assessment_plan_id => @plan.id, :academic_year_id => @plan.academic_year_id)
    @subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    @derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term)
    get_profiles
    get_profile_details(@assessment_group)
    get_course_subjects(@plan)
  end
  
  def create
    @assessment_group = params[:assessment_group][:type].constantize.new(params_for_assessment_group)
    @plan = @assessment_group.assessment_plan
    if @assessment_group.save
      flash[:notice] = t('assessment_group.flash1')
      redirect_to :controller => 'assessment_plans', :action => :show, :id => @plan.id
    else
      fetch_derivable_assessments
      @assessment_group.build_settings if @assessment_group.derived_assessment?
      get_profiles
      get_profile_details(@assessment_group)
      get_course_subjects(@plan)
      selected_subjects
      render :new
    end
  end
  
  def edit
    @assessment_group = AssessmentGroup.find(params[:id])
    @assessments_created = @assessment_group.assessments_present?
    @plan = @assessment_group.assessment_plan
    get_course_subjects(@plan)
    fetch_derivable_assessments
    get_profiles
    get_profile_details(@assessment_group)
    selected_subjects
  end
  
  def update
    @assessment_group = AssessmentGroup.find(params[:id])
    @assessment_group = @assessment_group.update_attributes_changing_type(params_for_assessment_group)
    @plan = @assessment_group.assessment_plan
    if @assessment_group.errors.empty?
      flash[:notice] = t('assessment_group.flash2')
      redirect_to :controller => 'assessment_plans', :action => :show, :id => @plan.id
    else
      @assessments_created = @assessment_group.assessments_present?
      get_course_subjects(@plan)
      fetch_derivable_assessments
      get_profiles
      get_profile_details(@assessment_group)
      selected_subjects
      render :edit
    end
  end
  
  def fetch_profiles
    instance_variable_set("@#{params[:profile_type].tableize}", params[:profile_type].constantize.find(params[:profile_id]))
    render :partial => params[:profile_type].tableize
  end
  
  def new_course_exam
    @academic_year = (params[:academic_year_id].present? ? AcademicYear.find(params[:academic_year_id]) : AcademicYear.active.first)
  end
  
  def course_exam_form
    @course = Course.find(params[:course_id])
    @batches = @course.batches.active
    @academic_year = (params[:academic_year_id].present? ? AcademicYear.find(params[:academic_year_id]) : AcademicYear.active.first)
    @assessment_group = SubjectAssessmentGroup.new(:parent => @course, :scoring_type => 1, :batches_id => (@batches.collect(&:id).join(',')), :academic_year_id => @academic_year.id)
    get_profiles
    get_profile_details(@assessment_group)
    render :partial => 'course_details'
  end
  
  def create_course_exam
    @assessment_group = params[:assessment_group][:type].constantize.new(params[:assessment_group])
    if @assessment_group.save
      flash[:notice] = t('assessment_group.flash1')
      redirect_to :controller => 'gradebooks', :action => :exam_management
    else
      @course = @assessment_group.parent
      @batches = @course.batches.active
      get_profiles
      get_profile_details(@assessment_group)
      render :new_course_exam
    end
  end
  
  def edit_course_exam
    @assessment_group = AssessmentGroup.find(params[:id])
    @assessment_group.batches_id = @assessment_group.assessment_group_batches.collect(&:batch_id).join(',')
    @course = @assessment_group.parent
    @batches = @course.batches.active
    @academic_year = @assessment_group.academic_year
    get_profiles
    get_profile_details(@assessment_group)
  end
  
  def update_course_exam
    @assessment_group = AssessmentGroup.find(params[:id])
    @assessment_group = @assessment_group.update_attributes_changing_type(params[:assessment_group])
    if @assessment_group.errors.empty?
      flash[:notice] = t('assessment_group.flash2')
      redirect_to :controller => 'gradebooks', :action => :exam_management
    else
      @course = @assessment_group.parent
      @batches = @course.batches.active
      get_profiles
      get_profile_details(@assessment_group)
      render :edit_course_exam
    end
  end
  
  def final_term_assessment
    parent = params[:parent_type].constantize.find(params[:parent_id])
    @plan = (params[:parent_type] == 'AssessmentPlan' ? parent : parent.assessment_plan)
    @term = parent unless params[:parent_type] == 'AssessmentPlan'
    @assessment_group = DerivedAssessmentGroup.new(:parent => parent, :scoring_type => 1, :assessment_plan_id => @plan.id, :academic_year_id => @plan.academic_year_id)
    @subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    @grade_exams = SubjectAssessmentGroup.without_mark_scoring(@plan,@term)
    @derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term)
    @activity_assessments = ActivityAssessmentGroup.fetch_all_assessments(@plan,@term)
    if @subject_assessments.present? or @derived_assessments.present?
      @subject_exams_with_marks = true
    else
      @subject_exams_with_marks = false
    end 
    get_profiles
    get_profile_details(@assessment_group)
    get_course_subjects(@plan)
  end
  
  def edit_final_term
    @assessment_group = AssessmentGroup.find(params[:id])
    @plan = @assessment_group.assessment_plan
    
    @term = @assessment_group.parent if @assessment_group.term_wise?
    @grade_exams = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
    @subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    @activity_assessments = ActivityAssessmentGroup.fetch_all_assessments(@plan,@term)
    @derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term) - [@assessment_group]
    if @subject_assessments.present? or @derived_assessments.present?
      @subject_exams_with_marks = true
    else
      @subject_exams_with_marks = false
    end
    if @assessment_group.no_exam
      @subject_assessments = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
    end
    #fetch_derivable_assessments
    get_profiles
    get_profile_details(@assessment_group)
    get_course_subjects(@plan)
    selected_subjects
  end
  
  def fetch_final_term_assessment_groups
    @assessment_group = AssessmentGroup.find(params.fetch(:assessment_group_id))
    @plan = AssessmentPlan.find(params.fetch(:assessment_plan_id))
    @term = @assessment_group.parent if @assessment_group.term_wise?
    no_exam = params[:no_exam]
    if no_exam == 'true'
      subject_assessments = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
    else
      subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    end
    derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term) - [@assessment_group]
    render :partial => 'subject_assessment_groups', :locals=>{:assessments => subject_assessments, :derived_assessments => derived_assessments, :obj => @assessment_group}
  end
  
  def fetch_final_term_assessment_groups_new
    @plan = AssessmentPlan.find(params.fetch(:assessment_plan_id))
    @term = AssessmentTerm.find_by_id(params.fetch(:assessment_term_id)) if params[:assessment_term_id].present?
    parent = @term.present? ? @term : @plan 
    if params[:assessment_group_id].present?
      @assessment_group = AssessmentGroup.find(params.fetch(:assessment_group_id))
    else
      @assessment_group = DerivedAssessmentGroup.new(:parent => parent, :scoring_type => 1, :assessment_plan_id => @plan.id, :academic_year_id => @plan.academic_year_id)
    end
    no_exam = params[:no_exam]
    if no_exam == 'true'
      subject_assessments = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
    else
      subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    end
    derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term) - [@assessment_group]
    render :partial => 'subject_assessment_groups', :locals=>{:assessments => subject_assessments, :derived_assessments => derived_assessments, :obj => @assessment_group}
  end
  
  def create_final_term
    @assessment_group = params[:assessment_group][:type].constantize.new(params_for_assessment_group)
    @plan = @assessment_group.assessment_plan
    if @assessment_group.save
      flash[:notice] = t('assessment_group.flash1')
      redirect_to :controller => 'assessment_plans', :action => :show, :id => @plan.id
    else
      fetch_form_with_params
      get_course_subjects(@plan)
      selected_subjects
      render :final_term_assessment
    end
  end
  
  def update_final_term
    @assessment_group = AssessmentGroup.find(params[:id])
    @assessment_group = @assessment_group.update_attributes_changing_type(params_for_assessment_group)
    @plan = @assessment_group.assessment_plan
    if @assessment_group.errors.empty?
      flash[:notice] = t('assessment_group.flash2')
      redirect_to :controller => 'assessment_plans', :action => :show, :id => @plan.id
    else
      get_course_subjects(@plan)
      selected_subjects
      fetch_form_with_params
      render :edit_final_term
    end
  end
  
  def planner_assessment
    if request.get?
      @plan = AssessmentPlan.find params[:assessment_plan_id]
      @assessment_group = @plan.final_assessment
    elsif request.put?
      @assessment_group = AssessmentGroup.find(params[:id])
      @assessment_group = @assessment_group.update_attributes_changing_type(params_for_assessment_group)
      if @assessment_group.errors.empty?
        redirect_success_planner
      else
        render_error_planner
      end
    elsif request.post?
      @assessment_group = params[:assessment_group][:type].constantize.new(params_for_assessment_group)
      if @assessment_group.save
        redirect_success_planner
      else
        render_error_planner
      end
    end
    selected_subjects
    get_course_subjects(@plan)
    get_profiles
    get_profile_details(@assessment_group)
  end
  
  def fetch_assessment_groups
    @plan = AssessmentPlan.find params[:assessment_plan_id]
    @assessment_group = @plan.final_assessment
    no_exam = params[:no_exam]
    assessments = if no_exam == 'true'
      @plan.connectable_assessments_for_no_exam
    else
      @plan.connectable_assessments
    end
    render :partial => 'planner_assessment_groups', :locals=>{ :assessments => assessments}
  end
  
  def reorder_assessments
    assessment = DerivedAssessmentGroup.find(params[:assessment_group_id], 
      :include => [:assessment_groups, {:derived_assessment_groups_associations => :assessment_group}])
    if assessment.update_attributes(params[:assessment_groups])
      flash[:notice] = t('exams_reorder_successfully')
    else
      flash[:notice] = t('exams_reorder_failed')
    end
    if assessment.final_planner_assessment?
      redirect_to :action => 'planner_assessment', :assessment_plan_id => assessment.assessment_plan_id
    else
      redirect_to :action => 'edit_final_term', :id => assessment.id
    end
  end
  
  
  private
  
  def render_error_planner
    @plan = @assessment_group.assessment_plan
    get_profiles
    get_profile_details(@assessment_group)
    @assessment_group.build_connectable_groups
    render :planner_assessment
  end
  
  def redirect_success_planner
    @plan = @assessment_group.assessment_plan
    flash[:notice] = t('assessment_group.flash3')
    redirect_to :assessment_plan_id => @plan.id
  end
  
  def get_profiles
    @attribute_profiles = AssessmentAttributeProfile.all(:joins => :assessment_attributes, :group => "assessment_attribute_profiles.id", :order=>"name ASC")
    @activity_profiles = AssessmentActivityProfile.all(:joins => :assessment_activities, :group => "assessment_activity_profiles.id")
    @grading_profiles = GradeSet.all(:joins => :grades, :group => "grade_sets.id")
    @direct_grades = GradeSet.all(:conditions => {:direct_grade => true}, :joins => :grades, :group => "grade_sets.id")
    @mark_grades = GradeSet.all(:conditions => {:direct_grade => false}, :joins => :grades, :group => "grade_sets.id")
  end
  
  def get_profile_details(group)
    @assessment_activity_profiles = group.assessment_activity_profile if group.assessment_activity_profile_id
    @assessment_attribute_profiles = group.assessment_attribute_profile if group.assessment_attribute_profile_id
    @grade_sets = group.grade_set if group.grade_set_id
  end
  
  def fetch_courses
    @courses = Course.active
  end
  
  def params_for_assessment_group
    key_for_hide_mark = params[:derived_assessment_group_settings].present? ? :derived_assessment_group_settings : :assessment_group
    params[:assessment_group][:hide_marks] = false if (params[key_for_hide_mark][:scoring_type].present? && params[key_for_hide_mark][:scoring_type] != "3")
    params_mod = params[:assessment_group]
    if params[:assessment_group][:type] == 'DerivedAssessmentGroup'
      params_mod[:derived_assessment_attributes] = params[:derived_assessment_group_settings]
      return params_mod
    else
      return params[:assessment_group]
    end
  end
  
  def fetch_derivable_assessments
    @term = @assessment_group.parent if @assessment_group.term_wise?
    if @assessment_group.no_exam
      @subject_assessments = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
    else
      @grade_exams = SubjectAssessmentGroup.without_mark_scoring(@plan, @term)
      @subject_assessments = SubjectAssessmentGroup.with_mark_scoring(@plan, @term)
    end
    @derived_assessments = DerivedAssessmentGroup.fetch_all_assessments(@plan,@term) - [@assessment_group]
    @activity_assessments = ActivityAssessmentGroup.fetch_all_assessments(@plan,@term)
  end
  
  def fetch_form_with_params
    fetch_derivable_assessments
    get_profiles
    get_profile_details(@assessment_group)
  end
  
  def selected_subjects
    @selected_subjects = []
    @assessment_group.override_assessment_marks.each do |osm|
      @selected_subjects << "subject_#{osm.subject_code}_#{osm.course_id}".gsub(/[^\w]/, '_')
    end
  end
  
  def get_course_subjects(plan)
    @course_subjects = (plan.courses.all(:joins => {:batches => :subjects}, :group => 'batches.course_id , subjects.code',:conditions => {:batches => {:is_active=> true, :subjects => {:no_exams => false, :elective_group_id => nil,:is_deleted => false}}},:select => 'courses.id as course_id, courses.course_name, subjects.id as subject_id, subjects.code as subject_code, subjects.name as subject_name, subjects.elective_group_id as subject_elective_id') + 
        plan.courses.all(:joins => {:batches => {:students => :subjects}}, :conditions => ["batches.is_active = true and subjects.no_exams = false and subjects.elective_group_id IS NOT NULL and subjects.is_deleted =false"] , :group => 'batches.course_id , subjects.code', 
        :select => 'courses.id as course_id, courses.course_name, subjects.id as subject_id, subjects.code as subject_code, subjects.name as subject_name, subjects.elective_group_id as subject_elective_id')).group_by(&:course_id)

  end
end

