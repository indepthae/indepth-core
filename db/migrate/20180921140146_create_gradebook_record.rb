class CreateGradebookRecord < ActiveRecord::Migration
  def self.up
    create_table :gradebook_records do |t|
      t.string :linkable_type
      t.integer :linkable_id
      t.references :record_group
      t.references :gradebook_record_group
      
      t.timestamps
    end
  end

  def self.down
    drop_table :gradebook_records
  end
end
