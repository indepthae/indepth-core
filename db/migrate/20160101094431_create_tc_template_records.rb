class CreateTcTemplateRecords < ActiveRecord::Migration
  def self.up
    create_table :tc_template_records do |t|
      t.integer :student_id
      t.integer :school_id
      t.string :prefix
      t.string :certificate_number
      t.date :date_of_issue
      t.text :record_data
      t.references :tc_template_version

      t.timestamps
    end
  end

  def self.down
    drop_table :tc_template_records
  end
end
