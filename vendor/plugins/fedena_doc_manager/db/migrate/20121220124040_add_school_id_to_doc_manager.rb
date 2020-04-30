class AddSchoolIdToDocManager < ActiveRecord::Migration
  def self.up
    [:folders,:documents,:folder_assignment_types,:privileged_folder_groups, :document_users, :shareable_folder_users].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:folders,:documents,:folder_assignment_types,:privileged_folder_groups, :document_users, :shareable_folder_users].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
