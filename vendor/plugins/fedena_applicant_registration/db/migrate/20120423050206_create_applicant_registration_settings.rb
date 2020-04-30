class CreateApplicantRegistrationSettings < ActiveRecord::Migration
  def self.up
    create_table :applicant_registration_settings do |t|
      t.integer :school_id
      t.string :key
      t.string :value
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_registration_settings
  end
end
