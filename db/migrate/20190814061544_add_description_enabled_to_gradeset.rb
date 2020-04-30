class AddDescriptionEnabledToGradeset < ActiveRecord::Migration
  def self.up
    add_column :grade_sets, :description_enabled, :boolean, :default=>false
  end

  def self.down
    remove_column :grade_sets, :description_enabled
  end
end
