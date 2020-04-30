class AddTemplateEditToSchool < ActiveRecord::Migration
  def self.up
    add_column :schools, :template_edit, :boolean , :default=>false
  end

  def self.down
    remove_column :schools, :template_edit
  end
end
