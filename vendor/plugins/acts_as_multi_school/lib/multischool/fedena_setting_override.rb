module MultiSchool
  module FedenaSettingOverride
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :company_details, :multi_school
        end
      end
    end

    module ClassMethods
      def company_details_with_multi_school
        school = MultiSchool.current_school
        if school && school.school_group.effective_white_label
          school.school_group.effective_white_label
        else
          company_details_without_multi_school
        end
      end      
    end
  end
end
