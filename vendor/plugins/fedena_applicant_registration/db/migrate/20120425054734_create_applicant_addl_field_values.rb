class CreateApplicantAddlFieldValues < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_field_values do |t|
      t.integer :school_id
      t.references :applicant_addl_field
      t.string :option
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_field_values
  end
end
