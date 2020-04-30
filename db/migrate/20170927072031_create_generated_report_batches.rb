class CreateGeneratedReportBatches < ActiveRecord::Migration
  def self.up
    create_table :generated_report_batches do |t|
      t.integer :generated_report_id
      t.integer :batch_id
      t.integer :generation_status, :default => 1
      t.boolean :report_published, :default => false
      t.text :last_error
      
      t.timestamps
    end
  end

  def self.down
    drop_table :generated_report_batches
  end
end
