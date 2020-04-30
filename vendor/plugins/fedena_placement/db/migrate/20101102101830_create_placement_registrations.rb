class CreatePlacementRegistrations < ActiveRecord::Migration
  def self.up
    create_table :placement_registrations do |t|
      t.references :student
      t.references :placementevent
      t.boolean :is_applied ,:default=>false
      t.boolean :is_approved
      t.boolean :is_attended,:default=>false
      t.boolean :is_placed,:default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :placement_registrations
  end
end
