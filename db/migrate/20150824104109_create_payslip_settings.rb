class CreatePayslipSettings < ActiveRecord::Migration
  def self.up
    create_table :payslip_settings do |t|
      t.string :section
      t.text :fields
      t.timestamps
    end
  end

  def self.down
    drop_table :payslip_settings
  end
end
