class AddFamilyIdToArchivedStudent < ActiveRecord::Migration
  def self.up
  	add_column :archived_students, :family_id, :integer
  end

  def self.down
  	remove_column :archived_students, :family_id
  end
end
