require 'dispatcher'
# FedenaDiscussion
module FedenaGallery
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_gallery do
      ::Student.instance_eval { has_many :gallery_tags, :as => :member }
      ::Employee.instance_eval { has_many :gallery_tags, :as => :member }
      ::Student.instance_eval { has_many :gallery_category_privileges, :as => :imageable}
      ::Employee.instance_eval { has_many :gallery_category_privileges, :as => :imageable }
      ::User.instance_eval { include  UserExtension }
      ::Student.instance_eval { include  StudentExtension }
    end
  end

  def self.dependency_delete(student)
    student.gallery_tags.destroy_all
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee" or record.class.to_s == "Student"
        return true if record.gallery_tags.present?
      end
    end
    return false
  end
  module UserExtension
    def has_gallery_privileges?
#------------deprecated method--------------------------
#      return true if self.privileges.map(&:name).include? "StudentView" or self.privileges.map(&:name).include?("StudentsControl") or self.privileges.map(&:name).include?("ManageUsers")
      return false
    end

  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_gallery_dependency, :student, :warning_message => :gallery_present ) do
          self.gallery_dependencies
        end
      end
    end

    def gallery_dependencies
      return false if self.gallery_tags.present?
      return true
    end
  end
end
