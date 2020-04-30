class AddUserIdToFormSubmission < ActiveRecord::Migration
  def self.up
    add_column :form_submissions, :user_id, :integer
  end

  def self.down
    remove_column :form_submissions, :user_id
  end
end
