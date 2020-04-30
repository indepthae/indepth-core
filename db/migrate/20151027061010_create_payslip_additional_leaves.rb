class CreatePayslipAdditionalLeaves < ActiveRecord::Migration
  def self.up
    create_table :payslip_additional_leaves do |t|
      t.references :employee_payslip
      t.references :employee_additional_leave
      t.date :attendance_date
      t.boolean :is_half_day
      t.timestamps
    end
  end

  def self.down
    drop_table :payslip_additional_leaves
  end
end
