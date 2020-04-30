class CreateBaseTemplates < ActiveRecord::Migration
  def self.up
    create_table :base_templates do |t|
      t.integer :template_for
      t.text :template_data
      t.string :profile_photo_type
      t.integer :profile_photo_dimension
      t.integer :school_id

      t.timestamps
    end
    add_index :base_templates,[:school_id]
  end

  def self.down
    drop_table :base_templates
  end
end
