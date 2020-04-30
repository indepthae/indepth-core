class UniqueIndexToTcTemplateRecord < ActiveRecord::Migration
  def self.up
    add_index :tc_template_records, :student_id,:unique=>true, :name=>:tc_template_student_unique_index
  end

  def self.down
    remove_index :tc_template_records, :student_id,:unique=>true, :name=>:tc_template_student_unique_index
  end
end
