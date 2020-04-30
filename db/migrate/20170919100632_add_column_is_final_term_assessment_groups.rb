class AddColumnIsFinalTermAssessmentGroups < ActiveRecord::Migration
  def self.up
    add_column :assessment_groups,  :is_final_term, :boolean, :default => false
  end

  def self.down
    remove_column :assessment_groups, :is_final_term
  end
end
