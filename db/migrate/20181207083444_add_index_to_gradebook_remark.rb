class AddIndexToGradebookRemark < ActiveRecord::Migration
  def self.up
    add_index :gradebook_remarks, [:student_id,:batch_id,:reportable_type,:reportable_id,:remarkable_type,:remarkable_id], :name => 'by_reportable_and_remarkable'
    add_index :remark_sets, [:assessment_plan_id,:target_type]
    add_index :remark_templates, :remark_bank_id
  end

  def self.down
    remove_index :gradebook_remarks, :name => 'by_reportable_and_remarkable'
    remove_index :remark_sets, [:assessment_plan_id,:target_type]
    remove_index :remark_templates, :remark_bank_id
  end
end
