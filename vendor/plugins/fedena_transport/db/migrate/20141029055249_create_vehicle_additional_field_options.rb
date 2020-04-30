class CreateVehicleAdditionalFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :vehicle_additional_field_options do |t|
      t.string :field_option
      t.references :vehicle_additional_field
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :vehicle_additional_field_options
  end
end
