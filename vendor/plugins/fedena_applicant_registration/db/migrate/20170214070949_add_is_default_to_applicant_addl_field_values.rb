class AddIsDefaultToApplicantAddlFieldValues < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_field_values, :is_default, :boolean, :default=>false
  end

  def self.down
    remove_column :applicant_addl_field_values, :is_default
  end
end
