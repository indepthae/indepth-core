class ChangePapeclipColumnMessageRecipient < ActiveRecord::Migration
  def self.up
    change_column :message_attachments,  :attachment_file_size, :integer
  end

  def self.down
  end
end
