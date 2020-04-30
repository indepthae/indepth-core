class CreateInstantFees < ActiveRecord::Migration
  def self.up
    create_table :instant_fees do |t|
      t.integer :instant_fee_category_id
      t.string :custom_category
      t.integer :payee_id
      t.string :payee_type
      t.string :guest_payee
      t.decimal :amount, :precision => 15, :scale => 2
      t.datetime :pay_date

      t.timestamps
    end
  end

  def self.down
    drop_table :instant_fees
  end
end
