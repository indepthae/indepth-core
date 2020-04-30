class CreateTableIndividualReportPdfs < ActiveRecord::Migration
  def self.up
    create_table :individual_report_pdfs do |t|
      t.references :individual_report
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.string  :attachment_file_size
      t.datetime  :attachment_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :individual_report_pdfs
  end
end
