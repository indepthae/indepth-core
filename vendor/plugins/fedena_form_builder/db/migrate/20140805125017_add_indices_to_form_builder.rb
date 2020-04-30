class AddIndicesToFormBuilder < ActiveRecord::Migration
  def self.up
    add_index :forms, [:form_template_id,:is_closed,:is_public,:is_feedback,:is_targeted], :name => 'index_by_form_properties'
    add_index :forms_users, [:user_id,:form_id], :name => 'index_by_fields'
    add_index :form_fields, [:form_template_id], :name => 'index_by_template_id'
    add_index :form_field_options, [:form_field_id], :name => 'index_by_field_id'
    add_index :form_file_attachments, [:form_field_file_id], :name => 'index_by_file_field_id'
    add_index :form_submissions, [:target,:ward_id,:form_id], :name => 'index_by_form_and_form_viewers'
    add_index :form_targets_users, [:user_id,:form_id], :name => 'index_by_form_target_users'
    add_index :form_templates, [:user_id], :name => 'index_by_users'
  end

  def self.down
    remove_index :forms, [:form_template_id,:is_closed,:is_public,:is_feedback,:is_targeted], :name => 'index_by_form_properties'
    remove_index :forms_users, [:user_id,:form_id], :name => 'index_by_fields'
    remove_index :form_fields, [:form_template_id], :name => 'index_by_template_id'
    remove_index :form_field_options, [:form_field_id], :name => 'index_by_field_id'
    remove_index :form_file_attachments, [:form_field_file_id], :name => 'index_by_file_field_id'
    remove_index :form_submissions, [:target,:ward_id,:form_id], :name => 'index_by_form_and_form_viewers'
    remove_index :form_targets_users, [:user_id,:form_id], :name => 'index_by_form_target_users'
    remove_index :form_templates, [:user_id], :name => 'index_by_users'
  end
end
