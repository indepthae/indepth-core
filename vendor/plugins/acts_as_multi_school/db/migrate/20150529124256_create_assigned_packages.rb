class CreateAssignedPackages < ActiveRecord::Migration
  def self.up
    create_table :assigned_packages do |t|
      t.integer :sms_package_id
      t.integer :assignee_id
      t.string :assignee_type
      t.boolean :is_using, :default=>false
      t.boolean :enable_sendername_modification, :default=>false
      t.string :sendername
      t.integer :sms_count
      t.date :validity
      t.integer :sms_used
      t.boolean :is_owner, :default=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :assigned_packages
  end
end
