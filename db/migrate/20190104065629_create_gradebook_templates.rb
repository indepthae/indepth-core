class CreateGradebookTemplates < ActiveRecord::Migration
  def self.up
    create_table :gradebook_templates do |t|
      t.string :name
      t.text   :template
      t.boolean :is_default, :default => false
      t.boolean :is_active, :default => true
      t.boolean :is_common, :default => true
      t.string :file_checksum
      
      t.timestamps
    end
  end

  def self.down
    drop_table :gradebook_templates
  end
end
