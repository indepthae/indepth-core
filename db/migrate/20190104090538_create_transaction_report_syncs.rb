class CreateTransactionReportSyncs < ActiveRecord::Migration
  def self.up
    create_table :transaction_report_syncs do |t|
      t.integer :transaction_id, :null => false
      t.string :transaction_type, :null => false
      t.boolean :sync_status, :default => 0
      t.boolean :is_income, :null => false
      t.integer :school_id

      t.timestamps
    end

    add_index :transaction_report_syncs, :school_id
    add_index :transaction_report_syncs, [:transaction_id, :transaction_type], :name => "by_transaction", :unique => true
    add_index :transaction_report_syncs, [:transaction_id, :sync_status], :name => "by_tran_id_and_sync_status"
  end

  def self.down
    remove_index :transaction_report_syncs, :name => "by_tran_id_and_sync_status"
    remove_index :transaction_report_syncs, :name => "by_transaction"
    remove_index :transaction_report_syncs, :school_id

    drop_table :transaction_report_syncs
  end
end
