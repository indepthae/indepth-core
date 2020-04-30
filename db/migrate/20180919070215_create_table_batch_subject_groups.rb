class CreateTableBatchSubjectGroups < ActiveRecord::Migration
  def self.up
    create_table :batch_subject_groups do |t|
      t.references :subject_group
      t.references :batch
      t.string  :name
      t.integer :priority
      t.timestamps
    end
  end

  def self.down
    drop_table :batch_subject_groups
  end
end
