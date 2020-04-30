class CreateHrReports < ActiveRecord::Migration
  def self.up
    create_table :hr_reports do |t|
      t.string :report_name
      t.string :name
      t.text :report_columns
      t.text :report_filters

      t.timestamps
    end
  end

  def self.down
    drop_table :hr_reports
  end
end
