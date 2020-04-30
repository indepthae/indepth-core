class CreateTransportGpsSync < ActiveRecord::Migration
  def self.up
    create_table :transport_gps_syncs do |t|
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.references :school
      t.timestamps
    end
  end

  def self.down
    drop_table :transport_gps_syncs
  end
end
