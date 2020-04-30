class CreateAssessmentReportSettings < ActiveRecord::Migration
  def self.up
    create_table :assessment_report_settings do |t|
      t.references :assessment_plan
      t.string :setting_key
      t.string :setting_value
      t.string  :signature_file_name
      t.string  :signature_content_type
      t.string  :signature_file_size
      t.datetime  :signature_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_report_settings
  end
end
