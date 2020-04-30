class AddHasPaidFeesForBatchColumnToStudents < ActiveRecord::Migration
  def self.up
    add_column :students, :has_paid_fees_for_batch, :boolean,:default=>false
  end

  def self.down
    remove_column :students, :has_paid_fees_for_batch
  end
end
