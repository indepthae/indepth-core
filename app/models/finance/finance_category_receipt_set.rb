# Associates FinanceFeeCategory / FinanceTransactionCategory and ReceiptNumberSet
class FinanceCategoryReceiptSet < ActiveRecord::Base
  belongs_to :category, :polymorphic => true
  belongs_to :receipt_number_set
end
