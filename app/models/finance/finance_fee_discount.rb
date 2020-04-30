class FinanceFeeDiscount < ActiveRecord::Base
  belongs_to :finance_fee_particular
  belongs_to :finance_fee
  belongs_to :fee_discount
end
