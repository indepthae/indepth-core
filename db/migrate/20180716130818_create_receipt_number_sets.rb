class CreateReceiptNumberSets < ActiveRecord::Migration
  def self.up
    create_table :receipt_number_sets do |t|
      t.string :name, :null => false
      t.string :sequence_prefix
      t.string :starting_number, :null => false
      t.integer :school_id

      t.timestamps
    end
    add_index :receipt_number_sets, :school_id, :name => "index_on_school_id"
    add_index :receipt_number_sets, [:sequence_prefix, :school_id], :name => "unique_sequence_prefix_in_school", :unique => true
  end

  def self.down
    drop_table :receipt_number_sets
  end
end
