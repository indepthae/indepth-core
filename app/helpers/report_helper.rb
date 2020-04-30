# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module ReportHelper
 
  def attendance_percent(batch,student)
    config = Configuration.get_config_value('StudentAttendanceType')
    end_date=Time.now.to_date
    month_date=batch.start_date.to_date
    if config == 'Daily'
      percent = Student.student_dailywise_attendance(batch,student,end_date,month_date)
      return percent
    elsif config == 'SubjectWise'
      percent = Student.student_subjectwise_attendance(batch,student,end_date,month_date)
      return percent
    end
    
  end
  
end
