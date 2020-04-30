class AddIsActiveToParticularPaymentAndDiscounts < ActiveRecord::Migration
  def self.up
    add_column :particular_payments, :is_active, :boolean, :default => true
    add_column :particular_discounts, :is_active, :boolean, :default => true

    add_index :particular_payments, :is_active, :name => "is_active"
    add_index :particular_discounts, :is_active, :name => "is_active"
  end

  def self.down
    remove_index :particular_discounts, :name => "is_active"
    remove_index :particular_payments, :name => "is_active"

    remove_column :particular_discounts, :is_active
    remove_column :particular_payments, :is_active
  end
end
