class CreateFinanceTaxPayments < ActiveRecord::Migration
  def self.up
    create_table :tax_payments do |t|
      t.references :taxed_entity, :polymorphic => true, :null =>  false
      t.references :taxed_fee, :polymorphic => true, :null =>  false
      t.decimal :tax_amount, :precision => 10, :scale => 4
      t.references :finance_transaction

      t.timestamps
    end
  end

  def self.down
    drop_table :tax_payments
  end
end
