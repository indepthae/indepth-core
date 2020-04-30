class RenameFamilyIdToFamilyid < ActiveRecord::Migration
  def self.up
  	rename_column :students, :family_id, :familyid
  	rename_column :guardians, :family_id, :familyid
  	rename_column :archived_students, :family_id, :familyid
  	rename_column :archived_guardians, :family_id, :familyid
  end
  
  def self.down
  	rename_column :students, :familyid, :family_id
  	rename_column :guardians, :familyid, :family_id
  	rename_column :archived_students, :familyid, :family_id
  	rename_column :archived_guardians, :familyid, :family_id
  end
end

