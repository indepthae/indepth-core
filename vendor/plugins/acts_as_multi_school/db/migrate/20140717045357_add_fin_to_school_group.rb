class AddFinToSchoolGroup < ActiveRecord::Migration
  def self.up
    add_column :school_groups, :fin, :string
  end

  def self.down
    remove_column :school_groups, :fin
  end
end
