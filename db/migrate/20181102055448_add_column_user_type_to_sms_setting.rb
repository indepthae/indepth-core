class AddColumnUserTypeToSmsSetting < ActiveRecord::Migration
  def self.up
    add_column :sms_settings, :user_type, :string
  end

  def self.down
    remove_column :sms_settings, :user_type, :string
  end
end
