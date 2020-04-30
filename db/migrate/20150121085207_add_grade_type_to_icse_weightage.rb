class AddGradeTypeToIcseWeightage < ActiveRecord::Migration
  def self.up
    add_column :icse_weightages, :grade_type, :string
  end

  def self.down
    remove_column :icse_weightages, :grade_type
  end
end
