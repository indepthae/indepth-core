module AttendanceReportHelper
  
  
  def daily_academic_day(batch, date)
    saved_attendance = MarkedAttendanceRecord.day_wise_working_days(batch,date)
    if saved_attendance.present?
      return true
    else
      return false
    end
  end
  
  def working_days(batch,date)
    return batch.working_days(date.to_date) 
  end
  
  
end