class AddColumnToAssessmentGroupBatch < ActiveRecord::Migration
  def self.up
    add_column :assessment_group_batches, :mark_entry_last_date, :date
  end

  def self.down
    remove_column :assessment_group_batches, :mark_entry_last_date
  end
end
