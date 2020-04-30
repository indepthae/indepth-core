class TcTemplateFieldsTcTemplateVersions < ActiveRecord::Migration
  def self.up
    create_table :tc_template_fields_tc_template_versions, :id => false do |t|
      t.integer :tc_template_field_id
      t.integer :tc_template_version_id
    end
  end
    
  def self.down
     drop_table :tc_template_fields_tc_template_versions 
  end
end
