class AddIndexToAdditionalDetails < ActiveRecord::Migration
  def self.up
    add_index :applicant_additional_details,:school_id, :name => "by_school_id"
    add_index :applicant_additional_details,:applicant_id, :name => "by_applicant_id"
    add_index :applicant_additional_details,:additional_field_id, :name => "by_additional_field_id"
  end

  def self.down
    remove_index :applicant_additional_details, :school_id
    remove_index :applicant_additional_details, :applicant_id
    remove_index :applicant_additional_details, :additional_field_id
  end
end
