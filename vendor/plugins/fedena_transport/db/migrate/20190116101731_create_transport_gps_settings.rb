class CreateTransportGpsSettings < ActiveRecord::Migration
  def self.up
    create_table :transport_gps_settings do |t|
      t.string :client_id
      t.string :client_secret
      t.references :school
      t.timestamps
    end
  end

  def self.down
    drop_table :transport_gps_settings
  end
end
