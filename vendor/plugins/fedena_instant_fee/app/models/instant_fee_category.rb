class InstantFeeCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :instant_fees
  has_many :instant_fee_particulars, :dependent => :destroy
  belongs_to :financial_year

  before_destroy :check_transaction
  validates_presence_of :financial_year_id, :if => Proc.new { |x| x.new_record? and (x.financial_year_id != '0' || x.financial_year_id == 0) }
  before_create :set_financial_year_id, :if => Proc.new { |x| x.new_record? }

  named_scope :current_active_financial_year, lambda { |x|
                                              {:conditions => ["financial_year_id #{FinancialYear.current_financial_year_id.present? ? '=' : 'IS'} ?",
                                                               FinancialYear.current_financial_year_id]} }
  named_scope :for_financial_year, lambda { |fy_id| {:conditions => ["financial_year_id #{fy_id.present? ? '=' : 'IS'} ?", fy_id]} }

  named_scope :active, {:conditions => "is_deleted = false"}

  def set_financial_year_id
    self.financial_year_id = nil if self.financial_year_id == '0' || self.financial_year_id == 0
  end

  def check_transaction
    if instant_fees.present?
      errors.add(:base, :instant_fees_exist)
      return false
    end
  end

  class << self
    def has_unlinked_particulars? category_id

      InstantFeeCategory.last(:conditions => ["instant_fee_categories.id = ? and ffp.master_fee_particular_id IS NULL",
                                             category_id],
                             :joins => "INNER JOIN instant_fee_particulars ffp
                                                ON ffp.instant_fee_category_id = instant_fee_categories.id",
                             :group => "instant_fee_categories.id").present?
    end
  end


end
