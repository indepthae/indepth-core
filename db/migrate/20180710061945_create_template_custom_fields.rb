class CreateTemplateCustomFields < ActiveRecord::Migration
  def self.up
    create_table :template_custom_fields do |t|
      t.string :name
      t.string :key
      t.references :corresponding_template, :polymorphic => true
      t.integer :school_id
      t.timestamps
    end
    add_index :template_custom_fields,[:school_id]
  end

  def self.down
    drop_table :template_custom_fields
  end
end
