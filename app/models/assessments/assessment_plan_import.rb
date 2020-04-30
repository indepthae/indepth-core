class AssessmentPlanImport < ActiveRecord::Base
  serialize :assessment_plan_ids, Array
  serialize :import_settings, Array
  serialize :last_error, Array
  validates_presence_of :assessment_plan_ids
  validates_presence_of :import_to, :import_from
  after_create :import, :remove_excess_entry
  
  SETTINGS = [:import_exam_group, :import_courses, :import_report_settings]
  IMPORTING_STATUS = {1 => t('importing'), 2 => t('completed'), 3 => t('failed'), 4 => t('partially_completed') }
  
  def assessment_plans
    AssessmentPlan.find_all_by_id(assessment_plan_ids, 
      :include => [:assessment_groups,{ :assessment_terms => :assessment_groups}, :courses, :assessment_report_settings])
  end
  
  def self.imported_planners(import_from, import_to)
    imports = all(:conditions => {:import_from => import_from, :import_to => import_to, :status => 2})
    plan_ids = imports.collect(&:assessment_plan_ids).flatten.compact
    AssessmentPlan.all(:conditions => {:academic_year_id => import_to, :previous_id => plan_ids}).collect(&:previous_id)
  end
  
  def fallbacked_assessment_plan_ids
    assessment_plan_ids || []
  end
    
  def import
    self.update_attributes(:status => 1)
    Delayed::Job.enqueue(self,{:queue => "gradebook"})
  end
  
  def perform
    obj = AssessmentPlanImport.find self.id ## self.update is not working
    @academic_year = AcademicYear.find import_to
    @existing_planner_courses = @academic_year.assessment_plans.all(:include => :courses).collect(&:course_ids).flatten.compact
    @errors = []
    @warnings = []
    has_completed_planner = false
    @assessment_group_trails = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    assessment_plans.each do |plan|
      @rollback = false
      ActiveRecord::Base.transaction do
        clone_assessment_plan(@academic_year, plan)
        if @rollback
          raise ActiveRecord::Rollback
        else
          has_completed_planner = true
        end
      end
    end
    if @errors.present? or @warnings.present?
      obj.update_attributes(:status => has_completed_planner ? 4 : 3, :last_error => @errors + @warnings) 
    else
      obj.update_attributes(:status => 2, :last_error => []) 
    end
  rescue Exception => e
    obj.update_attributes(:status => 3, :last_error => [e.message])
  end
  
  def clone_assessment_plan(academic_year, plan)
    plan_copy = academic_year.assessment_plans.build(plan.clone.attributes)
    plan_copy.previous_id = plan.id
    if plan_copy.save
      plan_copy.reload
      plan.assessment_terms.each do |term|
        clone_assessment_terms(plan_copy, term)
      end
      clone_course_associations(plan_copy, plan) if import_courses
      plan.assessment_groups.each do |group|
        clone_assessment_groups(plan_copy,group, plan_copy) #Building Plan Level Assessment Groups like planner exams, Term exams
      end
      clone_assessment_report_setting(plan_copy, plan) if import_report_settings
    else
      log_error! "<b>Plan - #{plan_copy.name}</b> : #{plan_copy.errors.full_messages.join(',')}" 
    end
  end
  
  def clone_assessment_report_setting(plan_copy, plan)
    plan.assessment_report_settings.each do |report_setting|
        setting = plan_copy.assessment_report_settings.build(report_setting.attributes.except('signature_updated_at','signature_file_name','signature_content_type','signature_file_size'))
        if report_setting.signature_file_name.present? #Recheck
          setting.signature = report_setting.signature
          setting.save
        end
    end
  end
  
  def clone_assessment_terms(plan, term)
    term_copy = plan.assessment_terms.build(term.clone.attributes.except('start_date','end_date'))
    term_copy.importing = true
    if term_copy.save
      term_copy.reload
      term.assessment_groups.each do |group|
        clone_assessment_groups(term_copy,group, plan)
      end
    else
      log_error! "<b>Term - #{term_copy}</b> : #{term_copy.errors.full_messages.join(',')}"
    end
  end
  
  def clone_assessment_groups(parent, group, plan)
    if import_exam_group
      
      group_copy = parent.assessment_groups.build(group.clone.attributes.merge({:assessment_plan_id => plan.id, :academic_year_id => import_to}))
      group_copy.type = group.class.to_s
      if group_copy.save
        group_copy.reload
        group_copy = AssessmentGroup.find group_copy.id ## For getting object of Derived Assessment Group Type
        @assessment_group_trails[group.id] = group_copy.id
        if group_copy.derived_assessment?
          clone_derived_assessment_group_setting(group_copy, group.derived_assessment_group_setting)
          clone_derived_assessment_groups_associations(group_copy, group)
        end
      else
        log_error! "<b>Exam - #{group_copy.name}</b> : #{group_copy.errors.full_messages.join(',')}"
      end
    end
  end
  
  def clone_derived_assessment_group_setting(group, dags)
    dags_copy = group.build_derived_assessment_group_setting(dags.clone.attributes)
    copy_val = dags_copy.value
    if copy_val.present?
      if copy_val.weightage.present?
        new_weightage = {}
        copy_val.weightage.each_pair do |ass_id, weightage|
          new_weightage[@assessment_group_trails[ass_id.to_i].to_s] = weightage if @assessment_group_trails[ass_id.to_i].present?
        end
        copy_val.weightage = new_weightage
        dags_copy.value = copy_val
      end
    end
    unless dags_copy.save
      log_error! "<b>Group Setting - #{group.name}</b> : #{dags_copy.errors.full_messages.join(',')}"
    end
  end
  
  def clone_derived_assessment_groups_associations(group_copy, group)
    id_array = []
    
    group.assessment_group_ids.each do |ass_id|
      id_array << @assessment_group_trails[ass_id]
    end
    group_copy.assessment_group_ids = id_array.compact
  end
  
  def clone_course_associations(copy, plan)
    course_ids = plan.course_ids
    common_courses = Course.find_all_by_id(course_ids & @existing_planner_courses)
    @warnings << I18n.t('importing_course_skipped',{:course_name => "#{common_courses.collect(&:full_name).join(',')}"}) if common_courses.present?
    copy.course_ids = plan.course_ids - @existing_planner_courses
  end
  
  def log_error!(msg)
    @rollback = true
    if msg.is_a?(Array)
      @errors = @errors + msg
    else
      @errors << msg
    end
  end
  
  def importing_status
    IMPORTING_STATUS[status]
  end
  
  def error_text
    text = "<ul>"
    last_error.each do |le|
      text << "<li>#{le}</li>"
    end
    text << '</ul>'
    
    text
  end
  
  def remove_excess_entry
    AssessmentPlanImport.first.destroy if AssessmentPlanImport.count > 15
  end
  
  SETTINGS.each do |method_name|
    define_method method_name do
      import_settings.present? and import_settings.include? method_name.to_s
    end
  end
  
end
