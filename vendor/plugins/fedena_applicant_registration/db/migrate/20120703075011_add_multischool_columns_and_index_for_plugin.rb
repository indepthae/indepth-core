class AddMultischoolColumnsAndIndexForPlugin < ActiveRecord::Migration
  def self.up
    add_column :pin_groups,:school_id, :integer
    add_column :pin_numbers,:school_id, :integer
    add_column :course_pins,:school_id, :integer
    #add_index :pin_groups,:school_id, :name => "by_school_id"
    #add_index :pin_numbers,:school_id, :name => "by_school_id"
    #add_index :course_pins,:school_id, :name => "by_school_id"
  end

  def self.down
    remove_column :pin_groups, :school_id
    remove_column :pin_numbers, :school_id
    remove_column :course_pins, :school_id
    remove_index :pin_groups, :school_id, :name => "by_school_id"
    remove_index :pin_numbers,:school_id, :name => "by_school_id"
    remove_index :course_pins,:school_id, :name => "by_school_id"
  end
end
