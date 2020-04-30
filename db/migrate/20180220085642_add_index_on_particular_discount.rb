class AddIndexOnParticularDiscount < ActiveRecord::Migration
  def self.up
    add_index :particular_discounts, :particular_payment_id
  end

  def self.down
    remove_index :particular_discounts, :particular_payment_id
  end
end
