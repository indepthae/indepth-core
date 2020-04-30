class AddNewFieldsToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :blood_group, :string
    add_column :applicants, :birth_place, :string
    add_column :applicants, :language, :string
    add_column :applicants, :religion, :string
    add_column :applicants, :student_category_id, :integer
  end

  def self.down
    remove_column :applicants, :blood_group
    remove_column :applicants, :birth_place
    remove_column :applicants, :language
    remove_column :applicants, :religion
    remove_column :applicants, :student_category_id
  end
end
