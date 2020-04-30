class CreateFormFields < ActiveRecord::Migration
  def self.up
    create_table :form_fields do |t|
      t.text :label
      t.integer :form_template_id
      t.string :field_type
      t.text :field_settings
      t.integer :placement_order
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :form_fields
  end
end
