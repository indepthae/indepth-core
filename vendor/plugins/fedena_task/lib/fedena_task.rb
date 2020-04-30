require 'dispatcher'
# FedenaTask
module FedenaTask
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_task do
      ::User.instance_eval { include UserExtension }
      ::Student.instance_eval { include  StudentExtension }
    end
  end

  def self.dependency_delete(student)
    student.user.tasks.destroy_all
    student.user.task_assignees.destroy_all
    student.user.assigned_tasks.destroy_all
  end
  
  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :tasks
        has_many :task_comments
        has_many :task_assignees,:foreign_key=>:assignee_id
        has_many :assigned_tasks,:through=>:task_assignees
      end
    end
  end

  
  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee" or record.class.to_s == "Student"
        return true if record.user.tasks.present?
        return true if record.user.task_assignees.present?
        return true if record.user.task_comments.present?
        return true if record.user.assigned_tasks.present?
      end
    end
    return false
  end
  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_task_dependency, :student, :warning_message => :task_present ) do
          self.task_dependencies
        end
      end
    end


    def task_dependencies
      return false if self.user.tasks.present? or self.user.task_assignees.present? or self.user.task_comments.present? or self.user.assigned_tasks.present?
      return true
    end
  end

end