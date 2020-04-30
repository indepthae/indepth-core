class AddIndexToTcTemplateField < ActiveRecord::Migration
  def self.up
     add_index :tc_template_versions, :is_active
     add_index :tc_template_fields_tc_template_versions, :tc_template_field_id, :name => 'index_tc_template_field_id'
     add_index :tc_template_fields_tc_template_versions, :tc_template_version_id, :name => 'index_tc_template_version_id'
     add_index :tc_template_fields, :type
  end

  def self.down
     remove_index :tc_template_versions, :is_active
     remove_index :tc_template_fields_tc_template_versions, :name => 'index_tc_template_field_id'
     remove_index :tc_template_fields_tc_template_versions, :name => 'index_tc_template_version_id'
     remove_index :tc_template_fields, :type
  end
end
