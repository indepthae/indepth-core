class AddHeaderFooterToFeeReceiptTemplate < ActiveRecord::Migration
  def self.up
    add_column :fee_receipt_templates, :header_content, :longtext
    add_column :fee_receipt_templates, :footer_content, :text
  end

  def self.down
    remove_column :fee_receipt_templates, :footer_content
    remove_column :fee_receipt_templates, :header_content
  end
end
