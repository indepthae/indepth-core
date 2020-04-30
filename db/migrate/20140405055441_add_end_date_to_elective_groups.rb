class AddEndDateToElectiveGroups < ActiveRecord::Migration
  def self.up
    add_column :elective_groups, :end_date, :date
  end

  def self.down
    remove_column :elective_groups, :end_date
  end
end
