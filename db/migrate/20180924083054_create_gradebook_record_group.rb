class CreateGradebookRecordGroup < ActiveRecord::Migration
  def self.up
    create_table :gradebook_record_groups do |t|
      t.references :assessment_plan
      t.string :name
      t.integer :priority
    end
  end

  def self.down
    drop_table :gradebook_record_groups
  end
end
