class CreateRemarks < ActiveRecord::Migration
  def self.up
    create_table :remarks do |t|
      t.integer :target_id
      t.integer :student_id
      t.integer :batch_id
      t.integer :submitted_by
      t.string :remark_subject
      t.string :remark_body
      t.string :remarked_by

      t.timestamps
    end
    add_index :remarks, :target_id
  end

  def self.down
    drop_table :remarks
  end
end
