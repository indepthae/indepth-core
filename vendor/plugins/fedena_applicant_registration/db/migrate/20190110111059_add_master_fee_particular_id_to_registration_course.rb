class AddMasterFeeParticularIdToRegistrationCourse < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :master_fee_particular_id, :integer
    add_index :registration_courses, :master_fee_particular_id, :name => "by_master_particular_id"
  end

  def self.down
    remove_index :registration_courses, :name => "by_master_particular_id"
    remove_column :registration_courses, :master_fee_particular_id
  end
end
