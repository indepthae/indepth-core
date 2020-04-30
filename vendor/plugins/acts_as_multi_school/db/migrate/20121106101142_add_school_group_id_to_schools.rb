class AddSchoolGroupIdToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :school_group_id, :integer
    add_column :schools, :creator_id, :integer
  end

  def self.down
    remove_column :schools, :school_group_id
    remove_column :schools, :creator_id
  end
end
