class AddFieldsToGroupedExamReport < ActiveRecord::Migration
  def self.up
    add_column :grouped_exam_reports, :percentage, :decimal, :precision => 15, :scale => 4, :null => true
  end

  def self.down
    remove_column :grouped_exam_reports, :percentage
  end
end
