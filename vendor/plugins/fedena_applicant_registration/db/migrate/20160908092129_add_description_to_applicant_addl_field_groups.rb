class AddDescriptionToApplicantAddlFieldGroups < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_field_groups, :description, :text
  end

  def self.down
    remove_column :applicant_addl_field_groups, :description
  end
end
