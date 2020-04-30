class AddBalanceColumnToTransportFee < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :balance,  :decimal, :precision=>15, :scale=>2
    TransportFee.update_all("balance=if(transaction_id is null,bus_fare,0)")
  end


  def self.down
    remove_column :transport_fees, :balance
  end
end
