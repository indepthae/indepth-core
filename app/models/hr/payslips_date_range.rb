class PayslipsDateRange < ActiveRecord::Base
  xss_terminate
  
  attr_accessor :generation_type
  has_many :employee_payslips, :dependent => :destroy
  belongs_to :payroll_group
  validates_presence_of :start_date, :end_date, :payroll_group_id
#  validates_uniqueness_of :payroll_group_id, :scope => [:start_date, :end_date], :message => :range_has_been_already_generated
  accepts_nested_attributes_for :employee_payslips

  before_save :validate_date_range
  before_save :set_revision_number

  def validate_date_range
    date_range = payroll_group.calculate_date_ranges(start_date)
    errors.add_to_base("Invalid range") unless date_range.first == start_date and date_range.last == end_date
    overlap_range = (payroll_group.payment_period == 3 ? payroll_group.payslips_date_ranges.all(:conditions => ["(? BETWEEN start_date AND end_date OR ? BETWEEN start_date AND end_date) AND (start_date <> ? AND end_date <> ?)", start_date, end_date, start_date, end_date]) : [])
    errors.add_to_base("Range overlaps") unless overlap_range.empty?
  end

  def date_range
    pg = self.payroll_group
    if pg.payment_period == 5
      return format_date(self.start_date,:format => :month_year)
    elsif pg.payment_period == 1
      return format_date(self.start_date)
    else
      return format_date(self.start_date) + " - " + format_date(self.end_date)
    end
  end

  def set_revision_number
    unless generation_type == 'bulk'
      rev_number = employee_payslips.collect(&:revision_number).max
      self.revision_number = rev_number
    end
  end

  private

  def association_valid?(reflection, association)
    if reflection.name == :employee_payslips
      return true if association.destroyed? || association.marked_for_destruction?
      return true if !association.changed?
      super
    else
      super
    end
  end
end