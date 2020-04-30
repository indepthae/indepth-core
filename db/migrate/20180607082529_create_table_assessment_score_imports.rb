class CreateTableAssessmentScoreImports < ActiveRecord::Migration
  def self.up
     create_table :assessment_score_imports do |t|
      t.integer :assessment_group_id
      t.string  :batch_id
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.string  :attachment_file_size
      t.datetime  :attachment_updated_at
      t.integer :status
      t.string  :last_message
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_score_imports
  end
end
