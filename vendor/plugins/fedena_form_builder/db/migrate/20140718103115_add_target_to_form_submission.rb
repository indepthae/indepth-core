class AddTargetToFormSubmission < ActiveRecord::Migration
  def self.up
    add_column :form_submissions, :target, :integer
  end

  def self.down
    remove_column :form_submissions, :target
  end
end
