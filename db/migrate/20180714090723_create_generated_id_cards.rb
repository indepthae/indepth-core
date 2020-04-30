class CreateGeneratedIdCards < ActiveRecord::Migration
  def self.up
    create_table :generated_id_cards do |t|
      t.text :id_card_html_front
      t.text :id_card_html_back
      t.references :issued_for, :polymorphic => true
      t.date :issued_on
      t.string :serial_no
      t.references :id_card_template
      t.integer :school_id
      t.timestamps
    end
    add_index :generated_id_cards,[:school_id]
  end

  def self.down
    drop_table :generated_id_cards
  end
end
