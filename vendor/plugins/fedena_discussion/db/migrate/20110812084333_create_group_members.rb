class CreateGroupMembers < ActiveRecord::Migration
  def self.up
    create_table :group_members do |t|
      t.references :group
      t.references :user
      t.boolean :is_admin, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :group_members
  end
end
