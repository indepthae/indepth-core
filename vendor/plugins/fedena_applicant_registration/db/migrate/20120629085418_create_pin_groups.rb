class CreatePinGroups < ActiveRecord::Migration
  def self.up
    create_table :pin_groups do |t|
      t.text :course_ids
      t.date :valid_from
      t.date :valid_till
      t.string :name
      t.integer :pin_count
      t.boolean :is_active

      t.timestamps
    end
  end

  def self.down
    drop_table :pin_groups
  end
end
