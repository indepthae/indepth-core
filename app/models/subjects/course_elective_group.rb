class CourseElectiveGroup < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  belongs_to :course
  has_many   :elective_groups
  has_many   :course_subjects, :as => :parent
  default_scope :order=>'priority ASC'
  after_destroy :detach_elective_groups
  validates_presence_of :name
  before_create :set_priority
  after_save  :sync_properties
  
  def self.configure_priorities(group_params)
    return unless group_params.present?
    groups = find_all_by_id(group_params.keys).to_a
    group_params.each_pair do |s_id, prio|
      group = groups.find{|s| s.id == s_id.to_i}
      group.priority = prio
      group.send(:update_without_callbacks)
    end
  end
  
  def set_priority
    last_priority = if self.parent_type == 'Course'
      course.subject_components_for_priority.last.try(:priority)
    elsif self.parent_type == 'SubjectGroup'
      last_element = self.parent.sorted_components.select{|c| !c.new_record? }.last
      priority = last_element.present? ? last_element.priority : self.parent.priority
      unless last_element.present?
        other_higer_components = course.subject_components_for_priority.select{|c| c.priority > priority}
        other_higer_components.each do |c| 
          c.priority = c.priority + 1
          c.save
        end
      end
      
      priority
    end
    
    self.priority = last_priority.present? ? (last_priority + 1) : 0
  end
  
  def find_or_create_e_group(batch_id)
    self.class.transaction do
      if parent_type == 'SubjectGroup'
        batch_group = parent.find_or_create_batch_groups(batch_id)
      end
      e_group = self.elective_groups.find_or_initialize_by_batch_id(batch_id)
      if e_group.new_record?
        e_group.attributes = self.attributes.except('parent_id','parent_type','created_at','updated_at','course_id', 'import_from', 'previous_id')
        e_group.batch_subject_group_id = batch_group.try(:id)
        e_group.save
        e_group.reload
      elsif e_group.is_deleted
        e_group.update_attributes(:is_deleted => false)
      end
      e_group      
    end
  end
  
  def is_primary?
    self.parent_type == 'Course'
  end
  
  def check_and_destroy
    if dependency_present?
      return false
    else
      self.destroy
    end 
  end\
    
  def sync_properties
    elective_groups.each do |eg|
      eg.attributes = self.attributes.except('parent_id','parent_type','created_at','updated_at','course_id', 'import_from', 'previous_id')
      eg.save
    end
  end
  
  def dependency_present?
    self.elective_groups.active.present? or course_subjects.present?
  end
  
  def detach_elective_groups
    self.elective_groups.each do |eg|
      eg.course_elective_group_id = nil
      eg.send(:update_without_callbacks)
    end
  end
end
