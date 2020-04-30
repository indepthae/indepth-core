class CreateTransportFeeCollections < ActiveRecord::Migration
  def self.up
    create_table :transport_fee_collections do |t|
      t.string :name
      t.references :batch
      t.date :start_date
      t.date :end_date
      t.date :due_date
      t.boolean    :is_deleted, :null => false, :default => false
    end
  end

  def self.down
    drop_table :transport_fee_collections
  end

  
end
