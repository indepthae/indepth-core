class AddFieldsToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :is_academically_cleared, :boolean
    add_column :applicants, :is_financially_cleared, :boolean
    add_column :applicants, :amount, :decimal,:precision => 12, :scale => 2
  end

  def self.down
    remove_column :applicants, :is_academically_cleared
    remove_column :applicants, :is_financially_cleared
    remove_column :applicants, :is_financially_cleared
  end
end
