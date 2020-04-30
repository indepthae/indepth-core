module Gradebook
  module Components
    class SubjectwiseAttendanceFactory < ComponentFactory
        
      def process_and_build_components
        return unless subjectwise_attendance_enabled?
        if @cumulative
          build_cumulative_subjectwise_attendance
        else
          build_subjectwise_attendance
        end
      end
      
      private
    
      def subjectwise_attendance_enabled?
        config = Configuration.find_by_config_key('StudentAttendanceType')
        config.config_value=="SubjectWise" and settings[:enable_attendance] == "1" ? true : false
      end
      
   
      
      def build_subjectwise_attendance
        @sub = @sub.select{|c| c.type == "Subject"}
        subjectwise_attendance = @reportable_child.subjectwise_attendance(@student,batch,@sub,assessment_date,holiday_event_dates)
      end  
      
      def build_cumulative_subjectwise_attendance
        @sub = @sub.select{|c| c.type == "Subject"}
        cumulative_subjectwise_attendance = @reportable_child.cumulative_subjectwise_attendance(@student,batch,@sub,assessment_date,holiday_event_dates)
      end     
    end
  end
end
      