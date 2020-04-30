class CreateTcTemplateFields < ActiveRecord::Migration
  def self.up
    create_table :tc_template_fields do |t|
      t.string :type
      t.integer :school_id
      t.text :field_name
      t.text :field_info
      t.integer :priority
      t.integer :parent_field_id
      t.timestamps
    end
  end

  def self.down
    drop_table :tc_template_fields
  end
end
