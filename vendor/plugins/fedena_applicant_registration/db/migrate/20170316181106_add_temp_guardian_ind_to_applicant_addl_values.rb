class AddTempGuardianIndToApplicantAddlValues < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_values, :temp_guardian_ind, :integer
  end

  def self.down
    remove_column :applicant_addl_values, :temp_guardian_ind
  end
end
