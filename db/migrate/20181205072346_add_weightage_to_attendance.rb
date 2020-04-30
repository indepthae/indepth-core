class AddWeightageToAttendance < ActiveRecord::Migration
  def self.up
    add_column :attendances, :weightage, :float
  end

  def self.down
    remove_column :attendances, :weightage
  end
end
