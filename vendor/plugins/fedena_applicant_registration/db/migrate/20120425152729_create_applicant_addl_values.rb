class CreateApplicantAddlValues < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_values do |t|
      t.integer :school_id
      t.references :applicant
      t.references :applicant_addl_field
      t.text :option
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_values
  end
end