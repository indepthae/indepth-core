class AddIsAmountColumnToRefundRule < ActiveRecord::Migration
  def self.up
    add_column :refund_rules, :is_amount, :boolean,:default=>false
    rename_column :refund_rules, :refund_percentage, :amount
  end

  def self.down
    remove_column :refund_rules, :is_amount
  end
end
