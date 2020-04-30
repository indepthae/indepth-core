class CreateTransportPassengerImports < ActiveRecord::Migration
  def self.up
    create_table :transport_passenger_imports do |t|
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.integer  :attachment_file_size
      t.datetime  :attachment_updated_at
      t.integer :status, :default => 0
      t.longtext  :last_message
      t.references :academic_year
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_passenger_imports
  end
end
