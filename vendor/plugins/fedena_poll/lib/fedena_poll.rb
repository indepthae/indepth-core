# FedenaPoll
require 'dispatcher'
module FedenaPoll
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_poll do
      ::Batch.instance_eval { has_many :poll_members, :as => 'member' }
      ::Batch.instance_eval { has_many :poll_question, :through=>:poll_members }
      ::Student.instance_eval { include  StudentExtension }
      ::EmployeeDepartment.instance_eval { has_many :poll_members, :as => 'member' }
      ::EmployeeDepartment.instance_eval { has_many :poll_question, :through=>:poll_members }
      ::Employee.instance_eval { delegate :poll_question ,:to=>:employee_department }
      ::User.instance_eval { include  UserExtension }
      DependencyHook.make_dependency_hook(:batch_poll_votes, :student, :warning_message=> :participated_in_the_poll ) do
        self.poll_votes_exists
      end
    end
  end

  def self.dependency_delete(student)
    user_id = student.user.id
    PollVote.destroy_all(:user_id => user_id)
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee" or record.class.to_s == "Student"
        return true if record.user.poll_votes.present?
      end
    end
    return false
  end

  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :poll_votes
      end
    end

    def already_voted?(poll_question_id)
      PollVote.find(:all,:conditions=>["user_id = ? and poll_question_id = ?",self.id,poll_question_id]).present?
    end

    def accessible_poll
      if self.admin
        poll = PollQuestion.find(:all)
      elsif self.student
        student = self.student_record
        poll = student.poll_question
      elsif self.employee
        employee = self.employee_record
        poll = employee.poll_question
      end
      return poll
    end
  end

  module StudentExtension
    def self.included (base)
      base.instance_eval do
        delegate :poll_question ,:to=>:batch
        DependencyHook.make_dependency_hook(:fedena_poll_dependency, :student, :warning_message => :poll_votes_present ) do
          self.poll_dependencies
        end
      end
    end

    def poll_dependencies
       return false if self.user.poll_votes.present?
       return true
    end

    def poll_votes_exists
      user.try(:poll_votes).select{|k| !k.try(:poll_question).try(:poll_members).select{|m| m.try(:member) == batch}.empty?}.empty?
    end
  end
  
  # unloadable
  def self.dashboard_layout_left_sidebar
    "poll_left_sidebar"
  end
  
end

