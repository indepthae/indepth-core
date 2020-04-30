require 'dispatcher'
# FedenaPlacement
module FedenaPlacement
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_placement do
      ::Student.instance_eval { has_many :placement_registrations }
      ::Student.instance_eval { has_many :placementevents ,:through=>:placement_registrations }
      ::Student.instance_eval { include  StudentExtension }
    end
  end

  def self.dependency_delete(student)
    PlacementRegistration.destroy_all(:student_id => student.id)
  end
  
  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student"
        return true if record.placement_registrations.present?
      end
    end
    return false
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_placement_dependency, :student, :warning_message => :placement_registration_present ) do
          self.placement_dependencies
        end
      end
    end

    def placement_dependencies
      return false if self.placement_registrations.present?
      return true
    end
  end
end

#
