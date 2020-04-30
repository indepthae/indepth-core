class AddColumnToSmsLog < ActiveRecord::Migration
  def self.up
    add_column :sms_logs, :user_name, :string
  end

  def self.down
    remove_column :sms_logs, :user_name
  end
end
