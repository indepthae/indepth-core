class CreateIaScores < ActiveRecord::Migration
  def self.up
    create_table :ia_scores do |t|
      t.decimal :mark,:precision =>15, :scale => 2
      t.references :student
      t.references :exam
      t.references :batch
      t.references :ia_indicator

      t.timestamps
    end
  end

  def self.down
    drop_table :ia_scores
  end
end
