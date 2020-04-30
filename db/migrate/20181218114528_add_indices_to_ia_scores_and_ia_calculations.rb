class AddIndicesToIaScoresAndIaCalculations < ActiveRecord::Migration
  def self.up
    add_index :ia_scores, :exam_id
    add_index :ia_calculations, :ia_group_id
  end

  def self.down
    remove_index :ia_scores, :exam_id
    remove_index :ia_calculations, :ia_group_id
  end
end
