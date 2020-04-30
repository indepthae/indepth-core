class DelayedStudentFeeDiscount

  attr_accessor :fee_category_id,:attributes


  def initialize(fee_category_id,attributes)
    @fee_category_id=fee_category_id
    @attributes=attributes
  end

  def perform
    @fee_category=FinanceFeeCategory.find(@fee_category_id)
    @fee_category.fee_discounts_attributes=@attributes['fee_discounts_attributes']
    @fee_category.save
  end
end