class CreateAdditionalReportPdfs < ActiveRecord::Migration
  def self.up
   create_table :additional_report_pdfs do |t|
    t.string :model_name
    t.string :method_name
    t.text :parameters
    t.text :opts
    t.string :pdf_report_file_name
    t.string :pdf_report_content_type
    t.integer :pdf_report_file_size
    t.datetime :pdf_report_updated_at
    t.boolean :status, :default => false

    t.timestamps
   end
  end 
  
  def self.down
    drop_table :additional_report_pdfs
  end
  
end
