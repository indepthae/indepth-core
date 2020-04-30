# FedenaAssigment
require 'dispatcher'

Dispatcher.to_prepare :fedena_assignment do
  ::Subject.instance_eval { has_many :assignments }
  ::Student.instance_eval { include StudentExtension }
  DependencyHook.make_dependency_hook(:assigned_assignments, :student, :warning_message=> :assignments_are_already_assigned ) do
    self.assigned_assignments_exists
  end
end

module FedenaAssignment
  def self.dependency_check(record,type)
    if type=="permanant"
      if record.class.to_s == "Student"
        return true if Assignment.find(:all, :conditions=>["find_in_set (#{record.id},student_list)"]).present?
      end
    end
    return false
  end

  def self.dependency_delete(student)
    records = Assignment.find(:all, :conditions=>["find_in_set (#{student.id},student_list)"])
    records.each do |row|
      stud_list = row.student_list.split(",")
      stud_list.delete(student.id.to_s)
      Assignment.find(row.id).update_attribute(:student_list,stud_list.join(","))
    end
  end
end

module StudentExtension
  def self.included(base)
    base.instance_eval do
      has_many :assignment_answers
      DependencyHook.make_dependency_hook(:fedena_assignment_dependency, :student, :warning_message => :assignment_present ) do
        self.assignment_dependencies
      end
    end
  end

  def assignment_dependencies
    return false if Assignment.find(:all, :conditions=>["find_in_set (#{self.id},student_list)"]).present?
    return true
  end
  
  def assigned_assignments_exists
    batch.subjects.select{|d| !d.try(:assignments).select{|y| y.try(:student_list).split(",").collect{|sp| sp.to_i}.include? id}.empty?}.empty?
  end
end
#
