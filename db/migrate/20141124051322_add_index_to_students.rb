class AddIndexToStudents < ActiveRecord::Migration
  def self.up
    add_index :students,:immediate_contact_id
  end

  def self.down
    remove_index :students,:immediate_contact_id
  end
end
