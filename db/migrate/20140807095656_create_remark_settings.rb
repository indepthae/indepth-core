class CreateRemarkSettings < ActiveRecord::Migration
  def self.up
    create_table :remark_settings do |t|
      t.string :target
      t.text :parameters
      t.string :table_name
      t.string :field_name
      t.string :remark_type
      t.boolean :general
      t.string :load_model
      
      t.timestamps
    end
  end

  def self.down
    drop_table :remark_settings
  end
end
