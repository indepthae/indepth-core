class AddIcseExamCategoryIdToExamGroup < ActiveRecord::Migration
  def self.up
    add_column    :exam_groups, :icse_exam_category_id, :integer
  end

  def self.down
    remove_column    :exam_groups, :icse_exam_category_id
  end
end
