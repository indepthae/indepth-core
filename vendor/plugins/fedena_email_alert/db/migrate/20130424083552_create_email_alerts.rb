class CreateEmailAlerts < ActiveRecord::Migration
  def self.up
    create_table :email_alerts do |t|
      t.string :model_name
      t.boolean :value
      t.string :mail_to

      t.timestamps
    end
  end

  def self.down
    drop_table :email_alerts
  end
end
