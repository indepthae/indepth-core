class IncreaseSizeOfFamilyId < ActiveRecord::Migration
  def self.up
  	change_column :students, :familyid, :integer, :limit => 8
  	change_column :guardians, :familyid, :integer, :limit => 8
  	change_column :archived_students, :familyid, :integer, :limit => 8
  	change_column :archived_guardians, :familyid, :integer, :limit => 8
  end

  def self.down
  	change_column :students, :familyid, :integer, :limit => 4
  	change_column :guardians, :familyid, :integer, :limit => 4
  	change_column :archived_students, :familyid, :integer, :limit => 4
  	change_column :archived_guardians, :familyid, :integer, :limit => 4
  end
end
