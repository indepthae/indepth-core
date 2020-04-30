class SmsPackageIndex < ActiveRecord::Migration
  def self.up
    add_index :assigned_packages, [:assignee_id,:assignee_type]
    add_index :assigned_packages, [:sms_package_id]
  end

  def self.down
  end
end
