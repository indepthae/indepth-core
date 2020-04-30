class CreateAssessmentGroupBatches < ActiveRecord::Migration
  def self.up
    create_table :assessment_group_batches do |t|
      t.references :assessment_group
      t.references :batch
      t.references :course
      t.boolean :marks_added, :default => false
      t.boolean :result_published, :default => false
      t.boolean :report_generated, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_group_batches
  end
end
