class CreateTransportFeeDiscounts < ActiveRecord::Migration
  def self.up
    create_table :transport_fee_discounts do |t|
      t.string :name
      t.references :transport_fee
      t.decimal :discount, :precision =>15, :scale => 2
      t.boolean :is_amount, :default=> false
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_fee_discounts
  end
end
