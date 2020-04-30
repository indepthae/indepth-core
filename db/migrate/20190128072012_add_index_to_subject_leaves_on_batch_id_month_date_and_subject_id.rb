class AddIndexToSubjectLeavesOnBatchIdMonthDateAndSubjectId < ActiveRecord::Migration
  def self.up
     add_index :subject_leaves, [:batch_id,:month_date] , :name => 'index_subject_leaves_on_batch_id_and_month_date'
     add_index :subject_leaves, [:subject_id] , :name => 'index_subject_leaves_on_subject_id'
     add_index :subject_leaves, [:month_date,:subject_id,:batch_id,:class_timing_id] , :name => 'index_month_date_and_subject_id_and_batch_id_and_class_timing_id'
  end

  def self.down
    add_index :subject_leaves, :name => 'index_subject_leaves_on_batch_id_and_month_date'
    add_index :subject_leaves, :name => 'index_subject_leaves_on_subject_id'
    add_index :subject_leaves, :name => 'index_month_date_and_subject_id_and_batch_id_and_class_timing_id'
  end
end
