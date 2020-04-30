class FinanceTransactionFine < ActiveRecord::Base
  belongs_to :finance_transaction
  belongs_to :multi_transaction_fine
end
