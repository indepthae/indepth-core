class AddExamTypeToOnlineExamGroups < ActiveRecord::Migration
  def self.up
    add_column :online_exam_groups, :exam_type, :string
    add_column :online_exam_groups, :exam_format, :string
    add_column :online_exam_groups, :result_published, :boolean, :default=>false
  end

  def self.down
    remove_column :online_exam_groups, :exam_type
    remove_column :online_exam_groups, :exam_format
    remove_column :online_exam_groups, :result_published
  end
end
