class CreateHrFormulas < ActiveRecord::Migration
  def self.up
    create_table :hr_formulas do |t|
      t.integer :value_type
      t.string :default_value
      t.integer :formula_id
      t.string :formula_type
      
      t.timestamps
    end
  end

  def self.down
    drop_table :hr_formulas
  end
end
