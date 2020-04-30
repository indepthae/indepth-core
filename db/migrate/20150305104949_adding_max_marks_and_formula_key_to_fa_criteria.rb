class AddingMaxMarksAndFormulaKeyToFaCriteria < ActiveRecord::Migration
  def self.up
    add_column :fa_criterias,:max_marks,:float,:default=>100.0
    add_column :fa_criterias,:formula_key,:string
  end

  def self.down
    remove_column :fa_criterias,:max_marks,:float
    remove_column :fa_criterias,:formula_key,:string
  end
end
