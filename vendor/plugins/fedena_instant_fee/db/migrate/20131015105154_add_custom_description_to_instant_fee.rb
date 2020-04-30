class AddCustomDescriptionToInstantFee < ActiveRecord::Migration
  def self.up
    add_column :instant_fees,:custom_description,:text
  end

  def self.down
    remove_column :instant_fees,:custom_description,:text
  end
end
