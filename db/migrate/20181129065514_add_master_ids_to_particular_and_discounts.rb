class AddMasterIdsToParticularAndDiscounts < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_particulars, :master_fee_particular_id, :integer
    add_column :fee_discounts, :master_fee_discount_id, :integer

    add_index :finance_fee_particulars, :master_fee_particular_id, :name => "index_by_master_fee_particular"
    add_index :fee_discounts, :master_fee_discount_id, :name => "index_by_master_fee_discount"
  end

  def self.down
    remove_index :fee_discounts, :master_fee_discount_id, :name => "index_by_master_fee_discount"
    remove_index :finance_fee_particulars, :master_fee_particular_id, :name => "index_by_master_fee_particular"

    remove_column :fee_discounts, :master_fee_discount_id
    remove_column :finance_fee_particulars, :master_fee_particular_id
  end
end
