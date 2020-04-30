class ChangeParticularAmountAndDiscountPrecision < ActiveRecord::Migration
  def self.up
    change_column :particular_payments, :amount, :decimal, :precision=>15, :scale=>4
    change_column :particular_discounts, :discount, :decimal, :precision=>15, :scale=>4
  end

  def self.down
    change_column :particular_payments, :amount, :decimal, :precision=>15, :scale=>2
    change_column :particular_discounts, :discount, :decimal, :precision=>15, :scale=>2
  end
end
