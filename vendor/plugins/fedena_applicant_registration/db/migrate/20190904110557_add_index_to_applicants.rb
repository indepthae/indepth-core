class AddIndexToApplicants < ActiveRecord::Migration
  def self.up
    add_index :applicants, [:submitted] , :name => 'index_applicants_on_submitted'
  end

  def self.down
    remove_index :applicants, :name => 'index_applicants_on_submitted'
  end
end
