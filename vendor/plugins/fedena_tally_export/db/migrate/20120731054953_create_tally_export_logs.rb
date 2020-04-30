class CreateTallyExportLogs < ActiveRecord::Migration
  def self.up
    create_table :tally_export_logs do |t|
      t.references :school
      t.references :finance_transaction
      t.boolean :status
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :tally_export_logs
  end
end
