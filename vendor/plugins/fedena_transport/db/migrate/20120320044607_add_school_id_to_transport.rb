class AddSchoolIdToTransport < ActiveRecord::Migration
  def self.up
    [:vehicles,:routes,:transports,:transport_fees,:transport_fee_collections].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:vehicles,:routes,:transports,:transport_fees,:transport_fee_collections].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
