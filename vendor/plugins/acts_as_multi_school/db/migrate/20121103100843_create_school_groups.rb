class CreateSchoolGroups < ActiveRecord::Migration
  def self.up
    create_table :school_groups do |t|
      t.string :name
      t.references :admin_user
      t.integer :parent_group_id
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :school_groups
  end
end
