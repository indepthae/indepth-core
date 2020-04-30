class AddIsDeletedToFormTemplate < ActiveRecord::Migration
  def self.up
    add_column :form_templates, :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :form_templates, :is_deleted
  end
end
