class AddFinancialYearIdToRegistrationCourse < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :financial_year_id, :integer
    add_index :registration_courses, :financial_year_id, :name => "index_by_fyid"
  end

  def self.down
    remove_index :registration_courses, :name => "index_by_fyid"
    remove_column :registration_courses, :financial_year_id
  end
end
