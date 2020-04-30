class AddPublishedDateToGeneratedReportBatch < ActiveRecord::Migration
  def self.up
     add_column :generated_report_batches, :published_date, :datetime
  end

  def self.down
     remove_column :generated_report_batches, :published_date
  end
end
