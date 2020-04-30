class ChangeHandlerTypeInDelayedJobs < ActiveRecord::Migration
  def self.up
    change_column :delayed_jobs, :handler, :mediumtext
  end

  def self.down
    change_column :delayed_jobs, :handler, :text
  end
end
