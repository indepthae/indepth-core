class CreateGatewayRequests < ActiveRecord::Migration
  def self.up
    create_table :gateway_requests do |t|
      t.string :gateway
      t.string :transaction_reference,  :limit => 36
      t.integer :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_requests
  end
end
