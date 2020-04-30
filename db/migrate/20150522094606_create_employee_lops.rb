class CreateEmployeeLops < ActiveRecord::Migration
  def self.up
    create_table :employee_lops do |t|
      t.integer :payroll_group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_lops
  end
end
