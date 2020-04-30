class CreateReportSettings < ActiveRecord::Migration
  def self.up
    create_table :report_settings do |t|
      t.string :setting_key
      t.string :setting_value
      t.timestamps
    end
  end

  def self.down
    drop_table :report_settings
  end
end
