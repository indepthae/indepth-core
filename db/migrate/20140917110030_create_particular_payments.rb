class CreateParticularPayments < ActiveRecord::Migration
  def self.up
    create_table :particular_payments do |t|
      t.decimal :amount, :precision =>15, :scale => 2
      t.references :finance_fee
      t.references :finance_fee_particular
      t.references :finance_transaction

      t.timestamps
    end
  end

  def self.down
    drop_table :particular_payments
  end
end
