class CreateStudentRecords < ActiveRecord::Migration
  def self.up
    create_table :student_records do |t|
      t.references :student
      t.integer :batch_id
      t.references :additional_field
      t.text     :additional_info
      t.timestamps
    end
  end

  def self.down
    drop_table :student_records
  end
end
