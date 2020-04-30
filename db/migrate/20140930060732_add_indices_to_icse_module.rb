class AddIndicesToIcseModule < ActiveRecord::Migration

  def self.up
    add_index :ia_indicators, :ia_group_id
    add_index :ia_scores, :ia_indicator_id
    add_index :exam_groups ,:icse_exam_category_id
    add_index :icse_reports,:exam_id
  end

  def self.down
    remove_index :ia_indicators, :ia_group_id
    remove_index :ia_scores, :ia_indicator_id
    remove_index :exam_groups ,:icse_exam_category_id
    remove_index :icse_reports,:exam_id
  end
end
