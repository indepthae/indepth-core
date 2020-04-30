class AddInheritSettingsToSchoolGroups < ActiveRecord::Migration
  def self.up
    add_column :school_groups, :inherit_sms_settings, :boolean, :default=>false
    add_column :school_groups, :inherit_smtp_settings, :boolean, :default=>false
  end

  def self.down
    remove_column :school_groups, :inherit_smtp_settings
    remove_column :school_groups, :inherit_sms_settings
  end
end
