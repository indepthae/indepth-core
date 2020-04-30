class AddingDiFormulaAndCriteriaFormulaToFaGroup < ActiveRecord::Migration
  def self.up
    add_column :fa_groups,:di_formula,:integer
    add_column :fa_groups,:criteria_formula,:string
  end

  def self.down
    remove_column :fa_groups,:di_formula
    remove_column :fa_groups,:criteria_formula
  end
end
