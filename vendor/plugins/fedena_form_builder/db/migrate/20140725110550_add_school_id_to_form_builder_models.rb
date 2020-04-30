class AddSchoolIdToFormBuilderModels < ActiveRecord::Migration
  def self.up
    add_column :forms, :school_id, :integer
    add_column :form_templates, :school_id, :integer
    add_column :form_submissions, :school_id, :integer
    add_column :form_fields, :school_id, :integer
    add_column :form_file_attachments, :school_id, :integer
    add_column :form_field_options, :school_id, :integer
  end

  def self.down
    remove_column :forms, :school_id
    remove_column :form_templates, :school_id
    remove_column :form_submissions, :school_id
    remove_column :form_fields, :school_id
    remove_column :form_file_attachments, :school_id
    remove_column :form_field_option, :school_id
  end
end
