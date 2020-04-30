class AddFamilyIdToArchiveGuardian < ActiveRecord::Migration
  def self.up
  	add_column :archived_guardians, :family_id, :integer
  end

  def self.down
  	remove_column :archived_guardians, :family_id
  end
end
