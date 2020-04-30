class CreateBookAdditionalFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :book_additional_field_options do |t|
      t.string :field_option
      t.references :book_additional_field

      t.timestamps
    end
  end

  def self.down
    drop_table :book_additional_field_options
  end
end
