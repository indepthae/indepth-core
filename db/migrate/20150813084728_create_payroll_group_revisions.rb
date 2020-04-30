class CreatePayrollGroupRevisions < ActiveRecord::Migration
  def self.up
    create_table :payroll_group_revisions do |t|
      t.references :payroll_group
      t.integer :revision_number
      t.text :categories
    end
  end

  def self.down
    drop_table :payroll_group_revisions
  end
end
