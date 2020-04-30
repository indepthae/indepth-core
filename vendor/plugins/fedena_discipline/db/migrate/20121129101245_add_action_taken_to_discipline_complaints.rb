class AddActionTakenToDisciplineComplaints < ActiveRecord::Migration
  def self.up
    add_column :discipline_complaints, :action_taken, :boolean,:default=>false
  end

  def self.down
    remove_column :discipline_complaints, :action_taken
  end
end
