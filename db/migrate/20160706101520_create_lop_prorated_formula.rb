class CreateLopProratedFormula < ActiveRecord::Migration
  def self.up
    create_table :lop_prorated_formulas do |t|
      t.integer :employee_lop_id
      t.integer :payroll_category_id
      t.boolean :actual_value, :default => false
      t.text :dependant_categories
      
      t.timestamps
    end
  end

  def self.down
    drop_table :lop_prorated_formulas
  end
end
