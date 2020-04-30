class AddIndexToFamilyId < ActiveRecord::Migration
  def self.up
	add_index :students, :familyid
	add_index :guardians, :familyid
	add_index :archived_students, :familyid
	add_index :archived_guardians, :familyid
  end

  def self.down
	remove_index :students, :familyid
	remove_index :guardians, :familyid
	remove_index :archived_students, :familyid
	remove_index :archived_guardians, :familyid
  end
end
