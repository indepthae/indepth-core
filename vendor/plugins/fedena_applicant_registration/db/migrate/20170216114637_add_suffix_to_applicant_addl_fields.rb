class AddSuffixToApplicantAddlFields < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_fields, :suffix, :string
  end

  def self.down
    remove_column :applicant_addl_fields, :suffix
  end
end
