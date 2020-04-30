class CreateSmsPackages < ActiveRecord::Migration
  def self.up
    create_table :sms_packages do |t|
      t.string :name
      t.string :service_provider
      t.integer :message_limit
      t.date :validity
      t.text :settings
      t.boolean :enable_sendername_modification, :default=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :sms_packages
  end
end
