class AddFontValueToTcTemplateVersion < ActiveRecord::Migration
  def self.up
    add_column :tc_template_versions, :font_value, :string, :default=>'normal'
  end

  def self.down
    remove_column :tc_template_versions, :font_value, :string
  end
end
