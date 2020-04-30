#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class ElectiveGroup < ActiveRecord::Base
  belongs_to :batch
  belongs_to :batch_subject_group
  belongs_to :course_elective_group
  
  has_many :subjects
  
  has_many :timetable_entries, :as => :entry

  validates_presence_of :name,:batch_id

  named_scope :for_batch, lambda { |b| { :conditions => { :batch_id => b, :is_deleted => false } } }
  validates_uniqueness_of :is_sixth_subject, :scope=>[:batch_id,:is_deleted] ,:if=> 'is_deleted == false and is_sixth_subject == true' , :message => "has already been assigned for this batch"

  named_scope :active, :conditions => {:is_deleted => false}
  before_save :import_groups, :if => Proc.new{|s| s.course_elective_group_id_changed? and s.course_elective_group_id.present? }
  
  after_update :deactivate_subject_group, :if => Proc.new{|s| s.is_deleted == true && s.batch_subject_group.present? }
  
  def validate
    errors.add :is_sixth_subject, "has already been assigned for this batch" if Subject.exists?(:is_sixth_subject => true,:batch_id=>self.batch_id,:is_deleted=>false) and self.is_sixth_subject == true
  end
  
  def inactivate
    unless subjects.active.present?
      update_attribute(:is_deleted, true)
      return true
    else
      return false
    end
  end
  
  def import_groups
    if batch_subject_group_id.nil? and (self.course_elective_group.parent_type == 'SubjectGroup')
      batch_group = self.course_elective_group.parent.find_or_create_batch_groups(self.batch_id)
      self.batch_subject_group_id = batch_group.try(:id)
    end
  end
  
  def unlinked_active_subjects
    subjects.select{|s| !s.is_deleted and s.course_subject_id.nil? }
  end

  def hour_count_check(tte_count)
    subs = []
    subjects.each do |sub|
      subs << sub.name if sub.max_weekly_classes <= tte_count and sub.is_deleted == false
    end
    subs
  end
  
  def dependency_present?
    self.subjects.active.present?
  end
  
  def deactivate_subject_group
    batch_subject_group.check_and_destroy
  end
  
end
