class AttendanceSetting < ActiveRecord::Base

  def self.attendance_lock_setting(key, value)
     config = find(:first, :conditions=>{:setting_key=>key,:user_type => 'Student'})
     config.nil? ?
       AttendanceSetting.create(:setting_key => key, :is_enable => value) :
       config.update_attributes(:is_enable => value) == true ? (config) : (config)
  end

  def self.create_attendance_lock_configuration
  [{:setting_key => 'AttendanceLock', :user_type => 'Student', :is_enable => false},
    {:setting_key => 'AttendanceLock', :user_type => 'Employee', :is_enable => false}
  ].each do |param|
  AttendanceSetting.find_or_create_by_setting_key_and_user_type(param)
   end
  end
  
  
  def self.is_attendance_lock
    attendance_lock = AttendanceSetting.find_by_setting_key('AttendanceLock') || nil
    attendance_lock =  attendance_lock.present? ? attendance_lock.is_enable : false
  end


end
