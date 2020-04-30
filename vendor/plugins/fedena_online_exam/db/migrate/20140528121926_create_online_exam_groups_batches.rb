class CreateOnlineExamGroupsBatches < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups_batches, :id => false do |t|
      t.references :online_exam_group
      t.references :batch
    end
  end

  def self.down
    drop_table :online_exam_groups_batches
  end
end
