class AddStudentIsPendingIndexToFinanceFee < ActiveRecord::Migration
  def self.up
    add_index :finance_fees, [:is_paid, :student_id] , :name => 'index_on_is_paid_and_student'
  end

  def self.down
    remove_index :finance_fees,  :name => "index_on_is_paid_and_student"
  end
end