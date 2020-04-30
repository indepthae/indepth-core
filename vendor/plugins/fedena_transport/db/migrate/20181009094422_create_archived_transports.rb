class CreateArchivedTransports < ActiveRecord::Migration
  def self.up
    create_table :archived_transports do |t|
      t.integer :receiver_id
      t.string :receiver_type
      t.references :academic_year
      t.integer :mode
      t.references :pickup_route
      t.references :drop_route
      t.references :pickup_stop
      t.references :drop_stop
      t.decimal :bus_fare, :precision => 15, :scale => 4
      t.boolean :auto_update_fare
      t.boolean :remove_fare
      t.date :applied_from
      t.references :school
      
      t.timestamps
    end
  end

  def self.down
    drop_table :archived_transports
  end
end
