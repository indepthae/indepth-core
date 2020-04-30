# Associates FinanceFeeCategory / FinanceTransactionCategory and FeeReceiptTemplate
class FinanceCategoryReceiptTemplate < ActiveRecord::Base
  belongs_to :category, :polymorphic => true
  belongs_to :fee_receipt_template
end
