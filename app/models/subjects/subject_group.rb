class SubjectGroup < ActiveRecord::Base
  belongs_to :course
  has_many   :course_subjects, :as => :parent
  has_many   :course_elective_groups, :as => :parent
  has_many   :batch_subject_groups
  default_scope :order=>'priority ASC'
  after_destroy :detach_batch_groups
  after_save  :sync_properties
  before_create :set_priority
  validates_presence_of :name
  
  def self.configure_priorities(group_params)
    return unless group_params.present?
    groups = find_all_by_id(group_params.keys).to_a
    group_params.each_pair do |s_id, prio|
      group = groups.find{|s| s.id == s_id.to_i}
      group.priority = prio
      group.save
    end
  end
  
  def set_priority
    last_prio = course.subject_components_for_priority.last.try(:priority)
    self.priority = last_prio.present? ? (last_prio + 1) : 0
  end
  
  def sorted_components
    components = []
    components += self.course_elective_groups
    components += self.course_subjects
    
    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end
  
  def check_and_destroy
    if dependency_present?
      return false
    else
      self.destroy
    end 
  end
  
  def is_primary?
    self.parent_type == 'Course'
  end
  
  def sync_properties
    batch_subject_groups.each do |bsg|
      bsg.attributes = self.attributes.except('course_id','created_at','updated_at', 'import_from', 'previous_id')
      bsg.save
    end
  end
  
  def dependency_present?
    course_subjects.present? or course_elective_groups.present?
  end
  
  def reset_subjects
    batch_subject_groups.each do |gp|
      gp.subject_group_id = nil
      gp.send(:update_without_callbacks)
    end
  end
  
  def find_or_create_batch_groups(batch_id)
    b_group = self.batch_subject_groups.find_or_initialize_by_batch_id(batch_id)
    if b_group.new_record?
      b_group.attributes = self.attributes.except('course_id','created_at','updated_at', 'import_from', 'previous_id')
      b_group.save
      b_group.reload
    elsif b_group.is_deleted
      b_group.update_attributes(:is_deleted => false)
    end
    
    b_group
  end
  
  def detach_batch_groups
    self.batch_subject_groups.each do |sg|
      sg.subject_group_id = nil
      sg.send(:update_without_callbacks)
    end
  end
end
