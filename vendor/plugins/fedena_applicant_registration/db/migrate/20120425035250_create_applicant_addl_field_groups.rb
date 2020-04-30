class CreateApplicantAddlFieldGroups < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_field_groups do |t|
      t.integer :school_id
      t.references :registration_course
      t.string :name
      t.boolean :is_active,:default=>true
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_fields
  end
end
