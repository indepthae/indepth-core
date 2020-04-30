class AddMultipartCharacterLimitToSmsPackages < ActiveRecord::Migration
  def self.up
    add_column :sms_packages, :multipart_character_limit, :integer
  end

  def self.down
    remove_column :sms_packages, :multipart_character_limit
  end
end
