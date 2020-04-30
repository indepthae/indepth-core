class SingleFeePayment < Payment
	# has only one finance payment
	has_one :finance_payment,:foreign_key=>"payment_id"
	has_one :finance_transaction,:through=> :finance_payment

end
