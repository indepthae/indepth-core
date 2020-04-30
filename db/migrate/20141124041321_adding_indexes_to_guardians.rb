class AddingIndexesToGuardians < ActiveRecord::Migration
  def self.up
    add_index :guardians,:user_id
    add_index :guardians,[:first_name,:last_name,:relation],:name=>:ward_guardian_index
  end

  def self.down
    remove_index :guardians,:user_id
    remove_index  :guardians,:name=>:ward_guardian_index
  end
end
