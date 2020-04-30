class AddColumnToOnlineExamScoreDetail < ActiveRecord::Migration
  def self.up
    add_column :online_exam_score_details, :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :online_exam_score_details, :is_deleted
  end
end
