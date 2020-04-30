class AddColumnCalculateFinalAndFormulaToSubjectGroups < ActiveRecord::Migration
  def self.up
    add_column :subject_groups, :calculate_final, :boolean, :default => false
    add_column :subject_groups, :formula, :string
    add_column :batch_subject_groups, :calculate_final, :boolean, :default => false
    add_column :batch_subject_groups, :formula, :string
  end

  def self.down
    remove_column :subject_groups, :calculate_final
    remove_column :subject_groups, :formula
    remove_column :batch_subject_groups, :calculate_final
    remove_column :batch_subject_groups, :formula
  end
end
