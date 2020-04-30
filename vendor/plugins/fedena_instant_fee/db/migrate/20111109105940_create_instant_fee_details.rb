class CreateInstantFeeDetails < ActiveRecord::Migration
  def self.up
    create_table :instant_fee_details do |t|
      t.integer :instant_fee_id
      t.integer :instant_fee_particular_id
      t.string :custom_particular
      t.decimal :amount, :precision => 15, :scale => 2
      t.decimal :discount,:precision => 15, :scale => 2
      t.decimal :net_amount,:precision => 15, :scale => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :instant_fee_details
  end
end
