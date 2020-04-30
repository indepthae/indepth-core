class CreateAdditionalSettings < ActiveRecord::Migration
  def self.up
    create_table :additional_settings do |t|
      t.integer :owner_id
      t.string :owner_type
      t.text :settings
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :additional_settings
  end
end
