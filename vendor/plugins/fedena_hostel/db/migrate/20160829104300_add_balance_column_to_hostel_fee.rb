class AddBalanceColumnToHostelFee < ActiveRecord::Migration
  def self.up
    add_column :hostel_fees, :balance,  :decimal, :precision=>15, :scale=>2
    HostelFee.update_all("balance=if(finance_transaction_id is null,rent,0)")
  end


  def self.down
    remove_column :hostel_fees, :balance
  end
end
