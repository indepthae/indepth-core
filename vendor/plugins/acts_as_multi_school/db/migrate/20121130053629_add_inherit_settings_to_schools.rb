class AddInheritSettingsToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :inherit_sms_settings, :boolean, :default=>false
    add_column :schools, :inherit_smtp_settings, :boolean, :default=>false
  end

  def self.down
    remove_column :schools, :inherit_smtp_settings
    remove_column :schools, :inherit_sms_settings
  end
end
