module MultiSchool
  module DelayedJob
    module DelayedJobForModel

      def self.included(base)
      
        base.class_eval do

          def perform_with_school_id
            MultiSchool.current_school = self.school
            perform_without_school_id
          end
        
          alias_method_chain :perform, :school_id if method_defined? :perform
    
        end
      
      end
      
    end
    
    module DelayedJobForClass
      def self.included(base)
        base.class_eval do

          def initialize_with_school_id(*args)
            initialize_without_school_id(*args)
            @school_id = MultiSchool.current_school.id
          end

          def perform_with_school_id
            MultiSchool.current_school = School.find @school_id
            perform_without_school_id
          end

        end
        base.alias_method_chain :initialize, :school_id 
        base.alias_method_chain :perform, :school_id
      end
    end 
  end  
end
