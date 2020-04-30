class AddFormerHasPaidFeesForBatchColumnToArchivedStudents < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :former_has_paid_fees_for_batch, :boolean
  end

  def self.down
    remove_column :archived_students, :former_has_paid_fees_for_batch
  end
end
