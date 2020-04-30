class CreateFormFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :form_field_options do |t|
      t.text :label
      t.integer :form_field_id
      t.integer :placement_order
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :form_field_options
  end
end
