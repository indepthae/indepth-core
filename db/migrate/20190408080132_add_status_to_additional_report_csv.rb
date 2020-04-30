class AddStatusToAdditionalReportCsv < ActiveRecord::Migration
  def self.up
    add_column :additional_report_csvs, :status, :boolean, :default => false
    add_index :additional_report_csvs, [:model_name,:method_name], :name => "index_on_method_and_model"
  end

  def self.down
    remove_column :additional_report_csvs, :status
    remove_index :particular_payments, :name => "index_on_method_and_model"
  end
end
