class CreateGeneratedReports < ActiveRecord::Migration
  def self.up
    create_table :generated_reports do |t|
      t.integer :report_id
      t.string :report_type
      t.references :course
      t.boolean :edited, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :generated_reports
  end
end
