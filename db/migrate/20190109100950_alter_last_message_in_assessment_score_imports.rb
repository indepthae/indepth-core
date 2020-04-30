class AlterLastMessageInAssessmentScoreImports < ActiveRecord::Migration
  def self.up
    change_column :assessment_score_imports, :last_message, :longtext
  end

  def self.down
  end
end
