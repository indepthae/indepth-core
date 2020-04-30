class AddColumnToPayrollCategories < ActiveRecord::Migration
  def self.up
    add_column :payroll_categories, :gross_dependent, :boolean, :default => false
  end

  def self.down
    remove_column :payroll_categories, :gross_dependent
  end
end
