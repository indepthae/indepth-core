class ParticularDiscount < ActiveRecord::Base
  belongs_to :particular_payment

  named_scope :for_particular_payments, lambda { |tran_id| {
                                          :conditions => ["particular_payments.finance_transaction_id = ?", tran_id],
                                          :joins => :particular_payment} }
end
