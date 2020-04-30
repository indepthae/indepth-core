class CreateStudentCoscholasticRemarkCopies < ActiveRecord::Migration
  def self.up
    create_table :student_coscholastic_remark_copies do |t|
      t.integer :student_id
      t.integer :batch_id
      t.integer :observation_id
      t.text :remark
      t.timestamps
    end
  end

  def self.down
    drop_table :student_coscholastic_remark_copies
  end
end
