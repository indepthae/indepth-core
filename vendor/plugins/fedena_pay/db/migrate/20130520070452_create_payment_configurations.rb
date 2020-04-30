class CreatePaymentConfigurations < ActiveRecord::Migration
  def self.up
    create_table :payment_configurations do |t|
      t.string  :config_key
      t.string  :config_value
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :payment_configurations
  end
end
