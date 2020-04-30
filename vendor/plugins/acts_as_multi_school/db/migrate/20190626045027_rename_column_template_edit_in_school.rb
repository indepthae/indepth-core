class RenameColumnTemplateEditInSchool < ActiveRecord::Migration
  def self.up
    rename_column :schools, :template_edit, :edit_sms_template
  end

  def self.down
    rename_column :schools, :edit_sms_template, :template_edit
  end
end
