class CreateApplicantAddlFields < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_fields do |t|
      t.integer :school_id
      t.references :applicant_addl_field_group
      t.string :field_name
      t.string :field_type
      t.boolean :is_active,:default=>true
      t.integer :position
      t.boolean :is_mandatory,:default=>true
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_fields
  end
end
