class CreateBookAdditionalFields < ActiveRecord::Migration
  def self.up
    create_table :book_additional_fields do |t|
      t.string :name
      t.boolean :is_mandatory
      t.string :input_type
      t.integer :priority
      t.boolean :is_active
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :book_additional_fields
  end
end
