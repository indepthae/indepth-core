class CreateFormulaAndConditions < ActiveRecord::Migration
  def self.up
    create_table :formula_and_conditions do |t|
      t.string :expression1
      t.string :expression2
      t.integer :operation
      t.string :value
      t.references :hr_formula
      
      t.timestamps
    end
  end

  def self.down
    drop_table :formula_and_conditions
  end
end
