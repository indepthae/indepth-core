class AddRoundOffValueToPayrollCategory < ActiveRecord::Migration
  def self.up
    add_column :payroll_categories, :round_off_value, :integer
  end

  def self.down
    remove_column :payroll_categories, :round_off_value
  end
end
