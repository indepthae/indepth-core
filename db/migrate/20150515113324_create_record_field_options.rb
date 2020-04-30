class CreateRecordFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :record_field_options do |t|
      t.string :field_option
      t.boolean :is_default,:default=>false
      t.references :record
      t.timestamps
    end
  end

  def self.down
    drop_table :record_field_options
  end
end
