class CreatePayrollGroups < ActiveRecord::Migration
  def self.up
    create_table :payroll_groups do |t|
      t.string :name
      t.integer :salary_type
      t.integer :payment_period
      t.integer :generation_day
      t.boolean :enable_lop, :default => false
      t.integer :current_revision, :default => 1
      t.integer :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :payroll_groups
  end
end
