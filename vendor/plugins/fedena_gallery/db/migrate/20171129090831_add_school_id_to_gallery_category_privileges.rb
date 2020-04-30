class AddSchoolIdToGalleryCategoryPrivileges < ActiveRecord::Migration
  def self.up
      add_column :gallery_category_privileges,:school_id,:integer
      add_index :gallery_category_privileges,:school_id
  end

  def self.down
    remove_index :gallery_category_privileges,:school_id
    remove_column :gallery_category_privileges,:school_id
  end
end
