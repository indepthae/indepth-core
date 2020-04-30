class CreateNumberSequences < ActiveRecord::Migration
  def self.up
    create_table :number_sequences, :id => false do |t|
      t.string :name
      t.integer :next_number, :default => 1
      t.string :sequence_type, :null => false
      t.integer :school_id
      
      t.timestamps
    end
    add_index :number_sequences, [:name, :sequence_type, :school_id], :unique => true, 
      :name => "index_by_name_and_sequence_type_and_school_id"
  end

  def self.down
    drop_table :number_sequences
  end
end