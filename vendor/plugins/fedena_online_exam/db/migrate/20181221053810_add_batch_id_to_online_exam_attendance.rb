class AddBatchIdToOnlineExamAttendance < ActiveRecord::Migration
  def self.up
    add_column :online_exam_attendances, :batch_id, :integer
  end

  def self.down
    remove_column :online_exam_attendances, :batch_id
  end
end
