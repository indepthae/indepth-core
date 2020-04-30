class CreateMessageTemplates < ActiveRecord::Migration
  def self.up
    create_table :message_templates do |t|
      t.string :template_name
      t.string :template_type
      t.string :automated_template_name
      t.integer :school_id
      t.timestamps
    end
    add_index :message_templates,[:school_id]
  end
  
  def self.down
    drop_table :message_templates
  end
end
