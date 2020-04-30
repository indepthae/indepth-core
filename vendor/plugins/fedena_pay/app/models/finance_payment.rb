class FinancePayment < ActiveRecord::Base
	belongs_to :fee_payment, :polymorphic => true
	belongs_to :fee_collection, :polymorphic => true
	belongs_to :finance_transaction
	belongs_to :payment
end
