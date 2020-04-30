class AddTransactionDateToParticularPayments < ActiveRecord::Migration
  def self.up
    add_column :particular_payments, :transaction_date, :date
    sql="update particular_payments  inner join finance_transactions on finance_transactions.id=particular_payments.finance_transaction_id set particular_payments.transaction_date = finance_transactions.transaction_date"
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :particular_payments,:transaction_date
  end
end
