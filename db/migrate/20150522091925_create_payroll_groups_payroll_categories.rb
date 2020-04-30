class CreatePayrollGroupsPayrollCategories < ActiveRecord::Migration
  def self.up
    create_table :payroll_groups_payroll_categories do |t|
      t.integer :payroll_group_id
      t.integer :payroll_category_id
      t.integer :sort_order
      t.timestamps
    end
  end

  def self.down
    drop_table :payroll_groups_payroll_categories
  end
end
