class CreateGeneratedPdfs < ActiveRecord::Migration
  def self.up
    create_table :generated_pdfs do |t|
      t.string :pdf_file_name
      t.string :pdf_content_type
      t.integer :pdf_file_size
      t.datetime :pdf_updated_at
      t.references :corresponding_pdf, :polymorphic => true
      t.integer :school_id
      t.timestamps
    end
    add_index :generated_pdfs,[:school_id]
  end

  def self.down
    drop_table :generated_pdfs
  end
end
