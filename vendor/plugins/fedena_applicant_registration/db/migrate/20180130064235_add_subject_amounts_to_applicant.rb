class AddSubjectAmountsToApplicant < ActiveRecord::Migration
  def self.up
    add_column :applicants, :subject_amounts, :text
  end

  def self.down
    remove_column :applicants, :subject_amounts
  end
end
