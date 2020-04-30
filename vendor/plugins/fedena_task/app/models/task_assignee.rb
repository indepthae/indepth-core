class TaskAssignee < ActiveRecord::Base
  belongs_to :assigned_task,:class_name=>"Task",:foreign_key=>:task_id
  belongs_to :assignee,:class_name=>"User"
  validates_uniqueness_of :assignee_id, :scope => :task_id, :message => :should_be_assigned_only_once
end
