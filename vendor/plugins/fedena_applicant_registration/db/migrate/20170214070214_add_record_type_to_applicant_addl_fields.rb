class AddRecordTypeToApplicantAddlFields < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_fields, :record_type, :string
  end

  def self.down
    remove_column :applicant_addl_fields, :record_type
  end
end
