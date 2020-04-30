class CreateMasterFeeDiscounts < ActiveRecord::Migration
  def self.up
    create_table :master_fee_discounts do |t|
      t.string :name
      t.string :description
      t.string :discount_type
      t.integer :school_id

      t.timestamps
    end

    add_index :master_fee_discounts, :school_id
  end

  def self.down
    drop_table :master_fee_discounts
  end
end
