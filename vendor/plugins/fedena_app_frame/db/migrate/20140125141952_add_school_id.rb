class AddSchoolId < ActiveRecord::Migration
  def self.up
    add_column :app_frames,:school_id,:integer
    add_index :app_frames,:school_id
  end

  def self.down
    remove_index :app_frames,:school_id
    remove_column :app_frames,:school_id
  end
end
