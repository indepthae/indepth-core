class AddColumnReportComponentInIndividualReports < ActiveRecord::Migration
  def self.up
    add_column :individual_reports, :report_component, :longtext
  end

  def self.down
    remove_column :individual_reports, :report_component
  end
end
