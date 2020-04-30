class RefundRule < ActiveRecord::Base
  belongs_to :finance_fee_collection
  belongs_to :user
  has_many :fee_refunds
  validates_uniqueness_of :refund_validity, :scope => [:finance_fee_collection_id]
  validates_presence_of :finance_fee_collection_id, :name
  validates_presence_of :amount, :if => :is_amount, :message => :blank
  validates_numericality_of :amount,:if => :is_amount, :allow_blank => true, :greater_than => 0
  # validates_inclusion_of :amount, :in => 1..100,:message=>:should_be_in_the_range_of_1_to_100,:allow_blank=>true ,:if=>"is_amount==false"

  def validate
    if refund_validity<Date.today
      errors.add_to_base(t("refund_validity_cant_be_a_past_date"))
    end
    if (!is_amount) and (amount.to_f <= 0.00 or amount.to_f > 100.00)
      errors.add_to_base(t("percentage_should_be_in_the_range_of_1_to_100"))
    end


  end

end
