class SalaryWorkingDay < ActiveRecord::Base
  xss_terminate
  
  validates_presence_of :payment_period
  validates_presence_of :working_days, :message => :enter_the_number_of_working_days
  validates_numericality_of :working_days, :message => :working_days_should_be_a_number, :if => lambda{|d| d.working_days.present?}
  DEFAULT_VALUES = {2 => 7, 3 => 14, 4 => 15, 5 => 30}
  MAX_VALUES = {2 => 7, 3 => 14, 4 => 15, 5 => 31}
  MONTH_VALUES = {1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31}
  def validate
    errors.add(:payment_period, :invalid) unless DEFAULT_VALUES.keys.include? payment_period
    if working_days.present? and is_number?(working_days)
      max_value = MAX_VALUES[payment_period.to_i]
      errors.add(:working_days, :working_days_limit_message, {:max_count => max_value}) unless (1..max_value).include? working_days.to_i
    end
    if is_number?(working_days)
    unless (working_days.to_f % 0.5 == 0.0)
      errors.add(:working_days, :working_days_as_whole_numbers)
    end
  end
  end

  def self.get_working_days(payment_period,month = nil)
    if payment_period == 5 and month.present?
      salary_working_day = find_by_payment_period_and_month_value(payment_period, month) 
    else
      salary_working_day = find_by_payment_period(payment_period)
    end
    working_days =
    if salary_working_day.present? and salary_working_day.working_days.present?
      salary_working_day.working_days
    else
      DEFAULT_VALUES[payment_period] || 1
    end
    return working_days
  end

  private
  def is_number?(num)
    /^(\+|-){0,1}[\d]+(\.[\d]+){0,1}$/ === num.to_s
  end
end







