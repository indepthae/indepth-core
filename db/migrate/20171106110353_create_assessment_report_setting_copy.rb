class CreateAssessmentReportSettingCopy < ActiveRecord::Migration
  def self.up
    create_table :assessment_report_setting_copies do |t|
      t.references :generated_report
      t.text :settings
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_report_setting_copies
  end
end
