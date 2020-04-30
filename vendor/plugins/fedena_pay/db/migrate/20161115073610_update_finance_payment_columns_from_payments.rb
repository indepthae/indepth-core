class UpdateFinancePaymentColumnsFromPayments < ActiveRecord::Migration
  insert_sql = "INSERT INTO finance_payments(finance_transaction_id,school_id,fee_payment_id,fee_payment_type,fee_collection_id,fee_collection_type,payment_id,created_at,updated_at) SELECT finance_transaction_id,school_id,payment_id,payment_type,fee_collection_id,fee_collection_type,id,created_at,updated_at FROM payments"
  delete_sql = "alter table payments drop column finance_transaction_id, drop column payment_id, drop column payment_type, drop column fee_collection_id, drop column fee_collection_type"
  update_sql = "update payments set type = 'SingleFeePayment'"
  ActiveRecord::Base.connection.execute(insert_sql)
  ActiveRecord::Base.connection.execute(delete_sql)
  ActiveRecord::Base.connection.execute(update_sql)
end