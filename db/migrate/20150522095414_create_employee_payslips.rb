class CreateEmployeePayslips < ActiveRecord::Migration
  def self.up
    create_table :employee_payslips do |t|
      t.integer :employee_id
      t.string :employee_type
      t.boolean :is_approved, :default => false
      t.integer :approver_id
      t.boolean :is_rejected, :default => false
      t.integer :rejector_id
      t.string :reason
      t.string :net_pay
      t.string :gross_salary
      t.string :lop
      t.string :days_count
      t.references :payslips_date_range
      t.references :finance_transaction
      t.integer :revision_number
      t.string :lop_amount
      t.string :working_days
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_payslips
  end
end
