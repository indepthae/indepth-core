class ChangeColumnOfSmsMessages < ActiveRecord::Migration
  def self.up
    change_column :sms_messages, :body, :text
  end

  def self.down
    change_column :sms_messages, :body, :string
  end
end
