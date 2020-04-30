class AddRollNumberColumnToTables < ActiveRecord::Migration
  def self.up
    add_column :courses,:roll_number_prefix,:string
    add_column :batches,:roll_number_prefix,:string
    add_column :students,:roll_number,:string
    add_column :archived_students,:roll_number,:string
    add_column :batch_students,:roll_number,:string
  end

  def self.down
    remove_column :courses,:roll_number_prefix,:string
    remove_column :batches,:roll_number_prefix,:string
    remove_column :students,:roll_number,:string
    remove_column :archived_students,:roll_number,:string
    remove_column :batch_students,:roll_number,:string
  end
end
