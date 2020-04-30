class CreateUpscaleScores < ActiveRecord::Migration
  def self.up
    create_table :upscale_scores do |t|
      t.integer :student_id
      t.integer :batch_id
      t.integer :subject_id
      t.string :upscaled_grade
      t.string :previous_grade

      t.timestamps
    end
  end

  def self.down
    drop_table :upscale_scores
  end
end
