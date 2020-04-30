class CreateLeaveGroups < ActiveRecord::Migration
  def self.up
    create_table :leave_groups do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_groups
  end
end
