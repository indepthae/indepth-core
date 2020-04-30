class CreateIcseReportSettingCopies < ActiveRecord::Migration
  def self.up
    create_table :icse_report_setting_copies do |t|
      t.integer :batch_id
      t.string :setting_key
      t.text    :data
      t.timestamps
    end
  end

  def self.down
    drop_table :icse_report_setting_copies
  end
end
