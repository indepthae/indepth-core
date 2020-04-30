class CreateBulkGeneratedIdCards < ActiveRecord::Migration
  def self.up
    create_table :bulk_generated_id_cards do |t|
      t.text :pdf_content
      t.references :id_card_template
      t.references :academic_year
      t.date :issued_on
      t.integer :school_id

      t.timestamps
    end
    add_index :bulk_generated_id_cards,[:school_id]
  end

  def self.down
    drop_table :bulk_generated_id_cards
  end
end
