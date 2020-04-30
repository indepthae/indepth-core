class AddDetailedReportFlagToIcseExamCategory < ActiveRecord::Migration
  def self.up
    add_column    :icse_exam_categories, :is_detailed_report, :boolean,:default=>true
  end

  def self.down
    remove_column    :icse_exam_categories
  end
end
