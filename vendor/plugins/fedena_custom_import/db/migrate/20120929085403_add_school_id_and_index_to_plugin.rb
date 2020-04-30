class AddSchoolIdAndIndexToPlugin < ActiveRecord::Migration
  def self.up
    add_column :exports, :school_id, :integer
    add_column :imports, :school_id, :integer
    add_column :import_log_details, :school_id, :integer
    add_index :exports, :school_id, :name => "by_school_id"
    add_index :imports, :school_id, :name => "by_school_id"
    add_index :import_log_details, :school_id, :name => "by_school_id"
  end

  def self.down
    remove_column :exports, :school_id
    remove_column :imports, :school_id
    remove_column :import_log_details, :school_id
    remove_index :exports, :name => "by_school_id"
    remove_index :imports, :name => "by_school_id"
    remove_index :import_log_details, :name => "by_school_id"
  end
end
