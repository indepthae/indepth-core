class ChangeMobileFieldInSmsLog < ActiveRecord::Migration
  def self.up
    change_column :sms_logs, :mobile, :text
  end

  def self.down
    change_column :sms_logs, :mobile, :string
  end
end
