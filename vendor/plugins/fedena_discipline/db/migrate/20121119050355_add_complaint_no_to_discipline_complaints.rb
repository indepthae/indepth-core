class AddComplaintNoToDisciplineComplaints < ActiveRecord::Migration
  def self.up
    add_column :discipline_complaints, :complaint_no, :string
  end

  def self.down
    remove_column :discipline_complaints, :complaint_no
  end
end
