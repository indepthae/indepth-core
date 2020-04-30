class RemoveReceiptPdfFromTr < ActiveRecord::Migration
  def self.up
    remove_column :transaction_receipts, :receipt_pdf_file_name
    remove_column :transaction_receipts, :receipt_pdf_content_type
    remove_column :transaction_receipts, :receipt_pdf_file_size
    remove_column :transaction_receipts, :receipt_pdf_updated_at
  end

  def self.down
    add_column :transaction_receipts, :receipt_pdf_file_name, :string
    add_column :transaction_receipts, :receipt_pdf_content_type, :string
    add_column :transaction_receipts, :receipt_pdf_file_size, :integer
    add_column :transaction_receipts, :receipt_pdf_updated_at, :datetime
  end
end
