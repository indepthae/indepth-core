class CreateTcTemplateVersions < ActiveRecord::Migration
  def self.up
    create_table :tc_template_versions do |t|
      t.boolean :is_active, :default => true
      t.integer :school_id
      t.float :header_space
      t.integer :footer_space
      t.boolean :header_settings_edit, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :tc_template_versions
  end
end
