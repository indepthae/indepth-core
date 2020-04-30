class ChangeCollationInMessages < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE messages modify body TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    execute "ALTER TABLE message_threads modify subject TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end

  def self.down
    execute "ALTER TABLE messages modify body TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci"
    execute "ALTER TABLE message_threads modify subject TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci"
  end
end
