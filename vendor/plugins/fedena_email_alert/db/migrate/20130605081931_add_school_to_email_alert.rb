class AddSchoolToEmailAlert < ActiveRecord::Migration
  def self.up
    add_column :email_alerts, :school_id, :integer
  end

  def self.down
    add_column :email_alerts, :school_id
  end
end
