class ChangeTransportFeesBalanceColumn < ActiveRecord::Migration
  def self.up
    change_column :transport_fees, :balance,  :decimal, :precision=>15, :scale=>4
  end

  def self.down
  end
end