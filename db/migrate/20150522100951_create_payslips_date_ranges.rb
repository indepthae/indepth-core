class CreatePayslipsDateRanges < ActiveRecord::Migration
  def self.up
    create_table :payslips_date_ranges do |t|
      t.date :start_date
      t.date :end_date
      t.references :payroll_group
      t.integer :revision_number
      t.timestamps
    end
  end

  def self.down
    drop_table :payslips_date_ranges
  end
end
