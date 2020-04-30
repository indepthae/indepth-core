class CreateAdvanceFeeWallets < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_wallets do |t|
      t.decimal :amount, :precision =>15, :scale => 2
      t.references :student
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_wallets
  end
end
