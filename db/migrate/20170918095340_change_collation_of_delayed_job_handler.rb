class ChangeCollationOfDelayedJobHandler < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE delayed_jobs modify handler TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end

  def self.down
    execute "ALTER TABLE delayed_jobs modify handler TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci"
  end
end
