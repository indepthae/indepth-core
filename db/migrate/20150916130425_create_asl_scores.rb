class CreateAslScores < ActiveRecord::Migration
  def self.up
    create_table :asl_scores do |t|
      t.references :student
      t.references :exam
      t.decimal    :speaking, :precision => 7, :scale => 2
      t.decimal    :listening, :precision => 7, :scale => 2
      t.decimal    :final_score, :precision => 7, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :asl_scores
  end
end
