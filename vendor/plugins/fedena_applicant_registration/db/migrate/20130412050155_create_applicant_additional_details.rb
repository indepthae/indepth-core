class CreateApplicantAdditionalDetails < ActiveRecord::Migration
  def self.up
    create_table :applicant_additional_details do |t|
      t.references :applicant
      t.references :additional_field
      t.string :additional_info
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_additional_details
  end
end
