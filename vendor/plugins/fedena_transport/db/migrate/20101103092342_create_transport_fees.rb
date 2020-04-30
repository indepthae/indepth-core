class CreateTransportFees < ActiveRecord::Migration
  def self.up
    create_table :transport_fees do |t|
      t.references :user
      t.decimal    :bus_fare, :precision => 8, :scale => 2
      t.references :transaction
      t.references :transport_fee_collection
      t.timestamps
    end
  end

  def self.down
    drop_table :transport_fees
  end
end
