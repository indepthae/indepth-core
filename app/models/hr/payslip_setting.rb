class PayslipSetting < ActiveRecord::Base
  xss_terminate
  
  serialize :fields, Array
  
  DEFAULT_SETTINGS = [{:employee_details => [0,1]},    {:additional_details => []},

    {:bank_details => []},
    {:attendance_details => []},
    {:payroll_details => []}
    
  ]

  validates_presence_of :fields, :if => "section == 'employee_details'"

  EMPLOYEE_DETAILS = {0=> :employee_name, 1 => :employee_number, 3 => :department, 2 => :date_of_joining, 4 => :category,5 => :position ,6 => :grade}

  ATTENDANCE_DETAILS = {4 => :lop,  1=> :no_of_working_days, 2 => :no_of_days_present, 3 => :no_of_days_absent }

  PAYROLL_DETAILS = {1 => :payment_frequency }

  def validate
      errors.add(:footnote, :blank) if section == 'footnote' and fields.present? and fields.first.blank?
  end

  class << self
      def footnote
        setting = find_by_section('footnote')
        setting.present? ? setting.fields.try(:first) : nil
      end
  end
  
end
