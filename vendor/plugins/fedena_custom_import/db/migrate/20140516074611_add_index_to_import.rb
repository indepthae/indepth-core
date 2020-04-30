class AddIndexToImport < ActiveRecord::Migration
  def self.up
    add_index  :imports, [:export_id]
  end

  def self.down
    remove_index  :imports, [:export_id]
  end
end
