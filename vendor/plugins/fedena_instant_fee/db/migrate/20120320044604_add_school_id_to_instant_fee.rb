class AddSchoolIdToInstantFee < ActiveRecord::Migration
  def self.up
    [:instant_fee_categories,:instant_fee_particulars,:instant_fees,:instant_fee_details].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:instant_fee_categories,:instant_fee_particulars,:instant_fees,:instant_fee_details].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
