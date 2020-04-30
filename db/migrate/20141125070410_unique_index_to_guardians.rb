class UniqueIndexToGuardians < ActiveRecord::Migration
  def self.up
    add_index :guardians, [:ward_id,:first_name,:last_name,:relation],:unique=>true, :name=>:ward_guardian_unique_index
  end

  def self.down
    remove_index :guardians,:name=>:ward_guardian_unique_index,:unique=>true
  end
end
