class AddNormalSubjectIdsToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :normal_subject_ids, :text
  end

  def self.down
    remove_column :applicants, :normal_subject_ids
  end
end
