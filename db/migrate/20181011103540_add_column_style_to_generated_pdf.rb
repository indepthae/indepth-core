class AddColumnStyleToGeneratedPdf < ActiveRecord::Migration
  def self.up
    add_column :generated_pdfs, :style, :string
  end

  def self.down
    remove_column :generated_pdfs, :style
  end
end
