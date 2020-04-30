class AddStudentCategoryIdToFinanceFee < ActiveRecord::Migration
  def self.up
    add_column :finance_fees, :student_category_id, :integer
  end

  def self.down
    remove_column :finance_fees, :student_category_id
  end
end
