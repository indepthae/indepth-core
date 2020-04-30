require 'dispatcher'

module FedenaCustomImport
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_custom_import do
      ::Guardian.instance_eval { include GuardianExtension }
      ::ExamScore.instance_eval { include ExamScoreExtension }
      if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name] }.include? "fedena_hostel"
        ::RoomDetail.instance_eval { include RoomDetailExtension }
      end
    end
  end

  module GuardianExtension
    def self.included(base)
      base.instance_eval do
        attr_accessor_with_default :set_immediate_contact, "NOSET"
        attr_accessor :ward_admission_number
        attr_accessor :is_father
        attr_accessor :is_mother
        attr_accessor :other_relation
        before_validation :modify_guardian_relation
        after_save :update_immediate_contact
      end

      def update_immediate_contact
        if set_immediate_contact.present?
          siblings = Student.find_all_by_admission_no_and_sibling_id(set_immediate_contact.split('|'), ward_id)
          siblings.each{ |sibling| sibling.update_attributes(:immediate_contact_id => id) }
        end
      end
      
      def modify_guardian_relation
        if is_father.present?
          self.relation = 'father'
        elsif is_mother.present?
          self.relation = 'mother'
        end
      end
    end
  end
  
  module RoomDetailExtension
    def self.included(base)
      base.instance_eval do
        attr_accessor :name_of_hostel
        attr_accessor :type_of_hostel
        before_validation :search_hostel_id
      end
      
      def search_hostel_id
        if type_of_hostel.present? and name_of_hostel.present?
          hostel = Hostel.find_by_name_and_hostel_type(self.name_of_hostel,self.type_of_hostel)
          if hostel.present?
            self.hostel_id = hostel.id
          else
            errors.add(:hostel_id, "not_found")
          end
        end
      end
      
    end
  end

  module ExamScoreExtension
    def self.included(base)
      base.instance_eval do
        before_validation :check_exam_score
      end
      def check_exam_score
        if exam.present? && exam.exam_group.present? && exam.exam_group.exam_type == 'Grades'
          self.marks = ''
        else
          self.grading_level_id = ''
        end
      end
    end
  end
end
