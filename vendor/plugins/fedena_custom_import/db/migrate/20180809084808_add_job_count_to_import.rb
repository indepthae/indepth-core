class AddJobCountToImport < ActiveRecord::Migration
  def self.up
     add_column :imports, :job_count, :integer, :default => 0
  end

  def self.down
    remove_column :imports, :job_count
  end
end
