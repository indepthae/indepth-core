class AddFamilyIdToStudentAndGuardian < ActiveRecord::Migration
  def self.up
  	add_column :students, :family_id, :integer
  	add_column :guardians, :family_id, :integer
  end

  def self.down
  	remove_column :students, :family_id
  	remove_column :guardians, :family_id
  end
end
