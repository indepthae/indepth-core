class CreateIndividualReports < ActiveRecord::Migration
  def self.up
    create_table :individual_reports do |t|
      t.integer :reportable_id
      t.string :reportable_type
      t.references :student
      t.references :generated_report_batch
      t.text :report
      
      t.timestamps
    end
  end

  def self.down
    drop_table :individual_reports
  end
end
