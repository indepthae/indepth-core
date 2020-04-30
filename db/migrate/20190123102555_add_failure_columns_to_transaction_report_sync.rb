class AddFailureColumnsToTransactionReportSync < ActiveRecord::Migration
  def self.up
    add_column :transaction_report_syncs, :last_error, :text
    add_column :transaction_report_syncs, :failed_at, :datetime
  end

  def self.down
    remove_column :transaction_report_syncs, :failed_at
    remove_column :transaction_report_syncs, :last_error
  end
end
