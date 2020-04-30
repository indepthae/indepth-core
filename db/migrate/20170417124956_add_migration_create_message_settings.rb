class AddMigrationCreateMessageSettings < ActiveRecord::Migration
  def self.up
    create_table :message_settings do |t|
      t.string  :config_key
      t.string  :config_value
      t.timestamps
    end
  end

  def self.down
    drop_table :message_settings
  end
end
