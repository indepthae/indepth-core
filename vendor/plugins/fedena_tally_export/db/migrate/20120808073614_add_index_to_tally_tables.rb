class AddIndexToTallyTables < ActiveRecord::Migration
  def self.up
    add_index :tally_export_logs, [:updated_at],:name => 'by_updation'
    add_index :tally_export_logs, [:status]
  end

  def self.down
    remove_index :tally_export_logs, [:status]
    remove_index :tally_export_logs,:name => 'by_updation'
  end
end
