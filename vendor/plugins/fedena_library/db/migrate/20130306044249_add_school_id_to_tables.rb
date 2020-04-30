class AddSchoolIdToTables < ActiveRecord::Migration
  def self.up
    [:book_additional_details,:book_additional_field_options].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:book_additional_details,:book_additional_field_options].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
