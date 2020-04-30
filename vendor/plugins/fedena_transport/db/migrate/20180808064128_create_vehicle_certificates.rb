class CreateVehicleCertificates < ActiveRecord::Migration
  def self.up
    create_table :vehicle_certificates do |t|
      t.references :certificate_type
      t.string :certificate_no
      t.date :date_of_issue
      t.date :date_of_expiry
      t.references :vehicle
      t.string  :certificate_file_name
      t.string  :certificate_content_type
      t.integer  :certificate_file_size
      t.datetime  :certificate_updated_at
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :vehicle_certificates
  end
end
