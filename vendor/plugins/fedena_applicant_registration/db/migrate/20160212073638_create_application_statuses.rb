class CreateApplicationStatuses < ActiveRecord::Migration
  def self.up
    create_table :application_statuses do |t|
      t.string :name
      t.string :description
      t.boolean :is_active, :default=>true
      t.boolean :notification_enabled, :default=>false
      t.boolean :is_default, :default=>false
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :application_statuses
  end
end
