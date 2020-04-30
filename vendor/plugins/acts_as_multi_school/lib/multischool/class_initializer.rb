module MultiSchool

  module ClassInitializer

    def self.included(base)
      base.class_eval do
        unless method_defined? "after_initialize"
          def after_initialize;end
        end
        unless method_defined? "after_initialize_with_school_id"
          def after_initialize_with_school_id
            after_initialize_without_school_id
            insert_school_id
          end
          alias_method_chain :after_initialize, :school_id
        end
      end
    end

    def insert_school_id
      self.school_id = MultiSchool.current_school.id if MultiSchool.current_school
    end
    
  end
  
end
