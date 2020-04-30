 
module FedenaDiscipline
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_discipline do
      ::User.instance_eval {include UserExtension}
      ::Student.instance_eval {include StudentExtension}
    end
  end

  def self.dependency_delete(student)
    user_id = student.user.id
    DisciplineParticipation.destroy_all(:user_id => user_id)
  end
  
  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :discipline_complaints
        has_many :discipline_participations
        has_many :discipline_comments
        has_many :discipline_actions
      end
    end
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student" or record.class.to_s == "Employee" or record.class.to_s == "Parent"
        return true if record.user.present? and record.user.discipline_participations.present?
      end
    end
    return false
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_discipline_dependency, :student, :warning_message => :discipline_action_present ) do
          self.discipline_dependencies
        end
      end
    end

    def discipline_dependencies
      return false if self.user.present? and self.user.discipline_participations.present?
      return true
    end
  end
end
