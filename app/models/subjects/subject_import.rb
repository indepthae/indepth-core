class SubjectImport < ActiveRecord::Base
  belongs_to :course
  serialize :parameters, Hash
  serialize :last_error, Array
  after_create :import, :remove_excess_entry
  attr_accessor :select
  IMPORT_MODELS = ['course_subject','course_elective_group', 'subject_group']
  IMPORTING_STATUS = {1 => t('importing'), 2 => t('completed'), 3 => t('failed'), 4 => t('completed_with_errors') }
  @@report_logger = Logger.new('log/gradebook_report_errors.log')
  
  def validate
    unless components_present_to_import?
      errors.add(:select, :select_any_subject_component)
    end
  end
  
  def components_present_to_import?
    self.parameters.present? and (self.parameters['subject_group_ids'].present? or self.parameters['course_elective_group_ids'].present? or self.parameters['course_subject_ids'].present?)
  end
  
  def import
    self.update_attributes(:status => 1)
    Delayed::Job.enqueue(self,{:queue => "gradebook"})
  end
  
  def perform
    obj = SubjectImport.find self.id
    @course = obj.course
    @errors = []
    [course_subjects, course_elective_groups, subject_groups].each do |component_array|
      component_array.each do |component|
        @rollback = false
        self.transaction do
          parent = get_parent(component)
          send("import_#{component.class.table_name}", component, parent)
          raise ActiveRecord::Rollback if @rollback
        end
      end
    end
    
    obj.update_attributes(:status => @errors.present? ? 4 : 2 , :last_error => @errors)
  rescue Exception => e
    log "---------Subject Import Log-----------------"
    log e.message
    log e.backtrace
    log "--------------------------"
    
    obj.update_attributes(:status => 3, :last_error => [e.message])
  end
  
  def import_course_subjects(subject, parent = @course)
    clone_components(subject, parent)
  end
  
  def import_course_elective_groups(e_group, parent = @course)
    new_egroup = clone_components(e_group, parent)
    return if @rollback
    
    e_group.course_subjects.each do |cs|
      import_course_subjects(cs, new_egroup)
    end
  end
  
  def import_subject_groups(subject_group, parent = nil)
    new_sgroup = clone_components(subject_group)
    return if @rollback
    subject_group.course_elective_groups.each do |ce|
      import_course_elective_groups(ce, new_sgroup)
    end
    
    subject_group.course_subjects.each do |cs|
      import_course_subjects(cs, new_sgroup)
    end
  end
  
  def clone_components(component, parent = nil)
    new_component = component.class.name.constantize.new(component.clone.attributes.except('created_at','updated_at'))
    unless component.is_a? SubjectGroup
      new_component.parent_id = parent.id
      new_component.parent_type = parent.class.name
    end
    new_component.course_id = @course.id
    new_component.import_from = import_from
    new_component.previous_id = component.id
    puts new_component.inspect
    log_error! "<b>#{new_component.class.table_name.titleize} - #{new_component.name}</b> : #{new_component.errors.full_messages.join(',')}" unless new_component.save
    
    new_component
  end
  
  def import_from
    self.parameters[:import_from]
  end
  
  def import_course_name(courses)
    courses.to_a.find{|c| c.id.to_s == import_from}.try(:course_name)
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
  
  def get_parent(component)
    unless component.is_a? SubjectGroup
      if component.parent_type == 'Course'
        @course
      elsif !component.parent_type.blank?
        component.parent_type.constantize.find_by_previous_id(component.parent_id)
      end
    end
  end
  
  def log_error!(msg)
    @rollback = true
    if msg.is_a?(Array)
      @errors = @errors + msg
    else
      @errors << msg
    end
  end
  
  def log(text)
    @@report_logger.info text
  end
  
  def remove_excess_entry
    imports = course.subject_imports
    imports.first.destroy if imports.count > 15
  end
  
  
  IMPORT_MODELS.each do |model_name|
    method_name = "#{model_name}s"
    define_method method_name.to_sym do
      if self.parameters.present? 
        model_name.titleize.delete(' ').constantize.find_all_by_id(self.parameters["#{model_name}_ids"])
      else
        []
      end
    end
  end
  
  
end