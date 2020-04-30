class CreateTransportFeeCollectionAssignments < ActiveRecord::Migration
  def self.up
    create_table :transport_fee_collection_assignments do |t|
      t.references :transport_fee_collection
      t.string :assignee_type
      t.integer :assignee_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_fee_collection_assignments
  end
end
