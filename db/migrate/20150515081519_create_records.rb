class CreateRecords < ActiveRecord::Migration
  def self.up
    create_table :records do |t|
      t.string :name
      t.string :suffix
      t.string :record_type
      t.references :record_group
      t.integer :priority
      t.boolean :is_mandatory
      t.string :input_type
      t.timestamps
    end
  end

  def self.down
    drop_table :records
  end
end
