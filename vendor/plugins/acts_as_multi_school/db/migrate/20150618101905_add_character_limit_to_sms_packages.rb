class AddCharacterLimitToSmsPackages < ActiveRecord::Migration
  def self.up
    add_column :sms_packages, :character_limit, :integer
  end

  def self.down
    remove_column :sms_packages, :character_limit
  end
end
