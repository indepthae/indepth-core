# Associates FinanceFeeCategory / FinanceTransactionCategory and FeeAccount
class FinanceCategoryAccount < ActiveRecord::Base
  belongs_to :category, :polymorphic => true
  belongs_to :fee_account
end
