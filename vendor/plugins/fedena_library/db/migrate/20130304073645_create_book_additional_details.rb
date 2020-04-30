class CreateBookAdditionalDetails < ActiveRecord::Migration
  def self.up
    create_table :book_additional_details do |t|
      t.references :book
      t.references :book_additional_field
      t.string :additional_info

      t.timestamps
    end
  end

  def self.down
    drop_table :book_additional_details
  end
end
