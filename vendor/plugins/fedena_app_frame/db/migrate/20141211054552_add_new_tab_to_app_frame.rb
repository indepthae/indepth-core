class AddNewTabToAppFrame < ActiveRecord::Migration
  def self.up
    add_column :app_frames, :new_tab, :boolean, :default => false
  end

  def self.down
    remove_column :app_frames, :new_tab
  end
end
