class AddFieldsToCceReports < ActiveRecord::Migration
  def self.up
    add_column :cce_reports,:subject_id,:integer
    add_column :cce_reports,:cce_exam_category_id,:integer
  end

  def self.down
    remove_column :cce_reports,:subject_id,:integer
    remove_column :cce_reports,:cce_exam_category_id,:integer
  end
end
