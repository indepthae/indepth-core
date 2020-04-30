class LeaveYear < ActiveRecord::Base

  has_one :reset_log
  has_many :credit_logs
  has_one :leave_reset
  validates_presence_of :name, :start_date, :end_date
  validates_uniqueness_of :name,:case_sensitive => false
  validates_length_of :name , :maximum => 25

  named_scope :active, :conditions => {:is_active => true}
  named_scope :inactive, :conditions => {:is_active => false}
  
  def validate
    if start_date > end_date
      errors.add(:start_date, :start_date_cant_be_after_end_date)
    else
      overlap = if new_record?
        LeaveYear.all(:conditions =>["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date))",
            start_date, end_date, start_date, end_date, start_date, end_date])
      else
        LeaveYear.all(:conditions =>["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)) AND id != ?",
            start_date, end_date, start_date, end_date, start_date, end_date, id])
      end
      if overlap.present?
        errors.add(:start_date, :overlap_existing_leave_year)
      else
        next_year = start_date.to_date + 1.year - 1
        errors.add(:end_date, :duration_minimum_one_year) if end_date < next_year
        errors.add(:end_date, :duration_maximum_one_year) if end_date > next_year
      end
      #  errors.add(:start_date, :start_date_should_be_more_than)   if start_date > Date.today
      #  errors.add(:end_date, :end_date_should_be_more_than)   if end_date < Date.today
    end
  end

  def range
    "#{format_date(start_date)} - #{format_date(end_date)}"
  end

  def make_active
    if validate_end_process
      self.class.update_all('is_active = false', ["school_id = ?", MultiSchool.current_school.id])
      self.reload
      self.update_attribute(:is_active, true)
    else
      return false
    end
  end

  def validate_end_process
    current_leave_year = LeaveYear.active.first
    if current_leave_year.present?
      end_year_reset = LeaveReset.find_all_by_leave_year_id(current_leave_year.id)
      credit_data = LeaveCredit.find_all_by_leave_year_id(current_leave_year.id)
      if !end_year_reset.present? and credit_data.present?
        return false
      else
        return true
      end
    else
      return true
    end
  end
  
  def duration
    TimeDuration.formatted_string(start_date, end_date, '%y, %M, %w, %d')
  end

  def dependencies_present?
    dependent = LeaveCredit.find_all_by_leave_year_id(id)
    if dependent.present? 
      return true
    else
      return false 
    end
  end

  def self.create_credit_configuration
    config = Configuration.get_config_value('AutomaticLeaveCredit')
    Configuration.set_value("AutomaticLeaveCredit", "0") if config == nil
  end

  def self.create_reset_configuration
    config = Configuration.get_config_value('LeaveResetSettings')
    Configuration.set_value("LeaveResetSettings", "0") if config == nil
  end
  
  def self.create_credit_date_configuration
    config = Configuration.get_config_value('LeaveCreditDateSettings')
    Configuration.set_value("LeaveCreditDateSettings", "0")  if config == nil
  end
  
  def self.credit_date_settings
    Configuration.get_config_value('LeaveCreditDateSettings') || "0"
  end
  
  def self.fetch_next_leave_year
    active_year = LeaveYear.active.first
    inactive_leave_years = LeaveYear.inactive.all
    next_leave_years = [] 
    inactive_leave_years.each do |year|
      next_leave_years << year if year.start_date > active_year.end_date
    end
    return next_leave_years if next_leave_years.present?
  end
  
  #  def self.check_year_end_process
  #    active_year = LeaveYear.active.first
  #    end_process = LeaveReset.find_by_leave_year_id(active_year.id)
  #    return true if end_process.present? 
  #  end
 
  def self.set_next_leave_year
    active_year = LeaveYear.active.first
    next_leave_year = LeaveYear.fetch_next_leave_year
    return next_leave_year if next_leave_year.present? and  active_year.update_attributes(:is_active => false)  and next_leave_year.update_attributes(:is_active => true)
  end
  
  def self.all_leave_years
    LeaveYear.all
  end
  
  def self.active_leave_year
    return  LeaveYear.active.first
  end

  def self.check_last_reset_date
    config = Configuration.get_config_value('LastResetDate')
    Configuration.set_value("LastResetDate", "0") if config == nil
  end
  
  def self.fetch_last_reset_date
    Configuration.get_config_value('LastResetDate') || "0"
  end
  
end
