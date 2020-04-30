class AddIsGeneratedToAdditionalReportCsvsAndAdditionalReportPdfs < ActiveRecord::Migration
  def self.up
    add_column :additional_report_csvs, :is_generated, :boolean, :default => false
    add_column :additional_report_pdfs, :is_generated, :boolean, :default => false
  end

  def self.down
    remove_column :additional_report_csvs, :is_generated
    remove_column :additional_report_pdfs, :is_generated
  end
end
