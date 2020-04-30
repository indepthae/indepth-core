class AddBatchIdToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :batch_id, :integer
  end

  def self.down
    remove_column :applicants, :batch_id
  end
end
