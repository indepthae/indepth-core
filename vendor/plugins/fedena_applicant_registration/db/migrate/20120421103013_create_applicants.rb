class CreateApplicants < ActiveRecord::Migration
  def self.up
    create_table :applicants do |t|
      t.integer :school_id
      t.string :reg_no
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.date :date_of_birth
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :country_id
      t.string :nationality_id
      t.string :pin_code
      t.string :phone1
      t.string :phone2
      t.string :email
      t.string :gender
      t.references :registration_course
      t.integer :photo_file_size
      t.string :photo_file_name
      t.string :photo_content_type
      t.string :status
      t.boolean :has_paid
      t.timestamps
    end
  end

  def self.down
    drop_table :applicants
  end
end
