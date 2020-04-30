class AddIndexToSequencePrefixOnReceiptNumberSet < ActiveRecord::Migration
  def self.up
    add_index :receipt_number_sets, :sequence_prefix, :name => "by_sequence_prefix"
  end

  def self.down
    remove_index :receipt_number_sets, :sequence_prefix, :name => "by_sequence_prefix"
  end
end
