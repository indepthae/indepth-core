class FinancialYear < ActiveRecord::Base
  # FinancialYear is made a timeline
  # # by default full timeline is Default Financial Year
  # when first FinancialYear (FY1) is created, timeline before the start date of FY1 is default financial year
  # any associated model with nil as financial_year_id is treated as associated with Default Financial Year
  # some places in views 0 is used to signify default financial year id, for all db comparisions nil must be used.

  has_many :finance_fee_categories
  has_many :finance_transactions
  has_many :cancelled_finance_transactions
  has_many :payslips, :class_name => "EmployeePayslip"
  has_many :finance_fee_collections
  has_many :advance_fee_categories

  named_scope :active, :conditions => {:is_active => true}
  named_scope :inactive, :conditions => {:is_active => false}
  named_scope :inclusive_of, lambda { |x| {:conditions => ["? BETWEEN start_date and end_date", x], :limit => 1} }

  ## Temporary fix::
  ## -> instant fee plugin dispatcher not working
  # has_many :instant_fee_categories
  # has_many :instant_fees

  validates_presence_of :name, :start_date, :end_date
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :maximum => 25

  def validate
    self.name = self.try(:name).try(:strip)
    if !new_record? and dependencies_present?
      errors.add(:start_date, :start_date_cant_be_modified) if start_date_changed?
      errors.add(:end_date, :end_date_cant_be_modified) if end_date_changed?
    end
    return if !new_record? and changes.blank?
    return unless start_date.present?
    return unless end_date.present?

    if (Date.parse(start_date.to_s) rescue nil).nil?
      errors.add(:start_date, :invalid)
    elsif (Date.parse(end_date.to_s) rescue nil).nil?
      errors.add(:end_date, :invalid)
    elsif start_date > end_date
      errors.add(:start_date, :start_date_cant_be_after_end_date)
    else
      errors.add(:start_date, :overlap_existing_financial_year) if (
      if new_record?
        FinancialYear.last(:conditions => ["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or
                                             (? BETWEEN start_date AND end_date) or
                                             (? BETWEEN start_date AND end_date))",
                                           start_date, end_date, start_date, end_date, start_date, end_date])
      else
        FinancialYear.last(:conditions => ["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or
                                             (? BETWEEN start_date AND end_date) or
                                             (? BETWEEN start_date AND end_date)) AND id != ?",
                                           start_date, end_date, start_date, end_date, start_date, end_date, id])
      end).present?

      errors.add(:date_range, :cannot_be_more_than_1_year) if (
        d1 = self.start_date
        d2 = self.end_date
        days = (d2 - d1).to_i + 1
        # days > (((Date.leap?(d1.year) && d1.month <= 2 && d1.day <= 29) or (Date.leap?(d2.year) && d2.month <= 2 && d2.day >= 29)) ? 366 : 365)
        days > ((Date.leap?(d1.year) or Date.leap?(d2.year)) ? 366 : 365)
      )
    end
  end

  def range
    "#{format_date(start_date)} - #{format_date(end_date)}"
  end

  def make_active
    self.class.update_all('is_active = false', ["school_id = ?", MultiSchool.current_school.id])
    self.reload
    self.update_attribute(:is_active, true)
  end

  def duration
    TimeDuration.formatted_string(start_date, end_date, '%y, %M, %w, %d')
  end

  def fetch_date_range
    return start_date, end_date
  end

  def dependencies_present?
    # TO DO :: check for all dependencies possible
    # core modules
    status = finance_fee_categories.last or finance_fee_collections.last or payslips.last or finance_transactions.last or
        cancelled_finance_transactions.last
    # transport plugin
    status ||= transport_fee_collections.last if FedenaPlugin.can_access_plugin?('fedena_transport')
    # hostel plugin
    status ||= hostel_fee_collections.last if FedenaPlugin.can_access_plugin?('fedena_hostel')
    # applicant registration plugin
    status ||= registration_courses.last if FedenaPlugin.can_access_plugin?('fedena_applicant_registration')
    # instant fee plugin
    status ||= instant_fee_categories.last || instant_fees.last if FedenaPlugin.can_access_plugin?('fedena_instant_fee')
    # library plugin
    status ||= book_movements.last if FedenaPlugin.can_access_plugin?('fedena_library')
    # Inventory plugin
    status ||= grns.last || invoices.last if FedenaPlugin.can_access_plugin?('fedena_inventory')
  end

  class << self
    def fetch_dates fy_id
      if fy_id.to_i == 0
        # returns date range for default financial year,
        # it will return a period of 1 year ending a day before of first financial year
        # if no financial year exists, it will return a period of 1 year till today ( as per current time zone settings)
        fetch_default_financial_year_range
      else
        fetch_financial_year_range fy_id
      end
    end

    def fetch_current_range
      fetch_dates current_financial_year_id
    end

    def fetch_financial_year_range fy_id
      fy = FinancialYear.find(fy_id)
      fy.fetch_date_range
    end

    def fetch_default_financial_year_range
      fy = FinancialYear.first(:order => "start_date")
      end_date = fy.present? ? (fy.start_date - 1.day) : Date.today_with_timezone
      start_date = end_date - 1.year

      return start_date, end_date
    end

    def has_valid_transaction_date tdate
      if can_be_default?(tdate) || inclusive_of(tdate).present?
        return true
      else
        return false
      end
    end

    def can_be_default? tdate
      !(FinancialYear.first(:conditions => [" start_date < ?", tdate], :order => "start_date").present?)
    end

    def fetch_and_set_financial_year
      fy = active.try(:last)
      FEDENA_SETTINGS[:current_financial_year] = fy.present? ? {:id => fy.id, :name => fy.name, :obj => fy} :
          {:id => 0, :name => t('financial_years.default_financial_year'), :obj => nil}
    end

    def current_financial_year_id
      fy_id = current_financial_year[:id] rescue nil
      fy_id == 0 ? nil : fy_id
    end

    def current_financial_year
      return FEDENA_SETTINGS[:current_financial_year] if FEDENA_SETTINGS[:current_financial_year].present?
      fetch_and_set_financial_year
    end

    def current_financial_year_name
      # TO DO
      fy = current_financial_year[:obj]
      fy.present? ? fy.name : t('financial_years.default_financial_year')
    end

    def fetch_name fy_id
      fy_id.present? ? find(fy_id).name : t('financial_years.default_financial_year')
    end

  end
end
