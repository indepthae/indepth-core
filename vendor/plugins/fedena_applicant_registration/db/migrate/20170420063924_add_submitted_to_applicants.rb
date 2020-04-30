class AddSubmittedToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :submitted, :boolean, :default=>true
  end

  def self.down
    remove_column :applicants, :submitted
  end
end
