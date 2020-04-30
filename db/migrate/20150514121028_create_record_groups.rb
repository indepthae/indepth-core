class CreateRecordGroups < ActiveRecord::Migration
  def self.up
    create_table :record_groups do |t|
      t.string :name
      t.boolean :is_active, :default=> true
      t.timestamps
    end
  end

  def self.down
    drop_table :record_groups
  end
end
