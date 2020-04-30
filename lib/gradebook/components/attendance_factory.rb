module Gradebook
  module Components
    class AttendanceFactory < ComponentFactory
        
      def process_and_build_components
        return unless attendance_enabled?
        build_attendance
      end
      
      private
    
      def attendance_enabled?
        # Attendance activation status.
        # Managed in Student Report settings page. 
        settings[:enable_attendance] == "1"
      end
      
      def is_manual_attendance?
        # Two modes of attendance. Manual and Automatic
        settings[:calculation_mode] == "1"
      end
      
      def build_attendance
        # calculate attendance for a student and returns attendance object
        if is_manual_attendance?
          attendance = @reportable_child.build_manual_attendance(@student.s_id,attendance_entries)
          total = (attendance.present?) ? attendance.total_working_days.to_f : nil
          attended = (attendance.present? and attendance.total_days_present.present?) ? attendance.total_days_present.to_f : nil
        else
          student_academic_days,leaves_total = @reportable_child.build_automatic_attendance(attendances,@student,assessment_date,batch,holiday_event_dates)
          if student_academic_days == "-"
            total,attended = "-","-"
          else  
            total = student_academic_days.to_f
            attended = (student_academic_days.to_f - leaves_total)
          end
        end
        Models::Attendance.new(
            :parent_name => @reportable_child.name,
            :parent_type => @reportable_child.class.table_name,
            :total => total,
            :attended => attended
          )
      end
      
    end
  end
end
      