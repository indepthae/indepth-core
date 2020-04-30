class CreateClassrooms < ActiveRecord::Migration
  def self.up
    create_table :classrooms do |t|
      t.string :name
      t.integer :building_id
      t.integer :capacity
      t.timestamps
    end
  end

  def self.down
    drop_table :classrooms
  end
end
