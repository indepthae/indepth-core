class AddIndicesToTransportFeeCollectionAssignments < ActiveRecord::Migration
  def self.up
    add_index :transport_fee_collection_assignments, :transport_fee_collection_id, :name => "index_by_tf_collection_id"
    add_index :transport_fee_collection_assignments, [:assignee_id, :assignee_type], :name => "index_by_assignee"
    add_index :transport_fee_collection_assignments, :school_id, :name => "index_by_school_id"
  end

  def self.down
    remove_index :transport_fee_collection_assignments, [:assignee_id, :assignee_type], :name => "index_by_assignee"
    remove_index :transport_fee_collection_assignments, :transport_fee_collection_id, :name => "index_by_tf_collection_id"
    remove_index :transport_fee_collection_assignments, :school_id, :name => "index_by_school_id"
  end
end
