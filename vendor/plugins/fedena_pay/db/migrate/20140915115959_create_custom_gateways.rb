class CreateCustomGateways < ActiveRecord::Migration
  def self.up
    create_table :custom_gateways do |t|
      t.string :name
      t.text :gateway_parameters
      t.timestamps
    end
  end

  def self.down
    drop_table :custom_gateways
  end
end
