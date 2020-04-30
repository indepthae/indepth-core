class AddHeaderContentFieldsToFeeReceiptTemplate < ActiveRecord::Migration
  def self.up
    add_column :fee_receipt_templates, :header_content_a5_portrait, :longtext
    add_column :fee_receipt_templates, :header_content_thermal_responsive, :longtext
  end

  def self.down
    remove_column :fee_receipt_templates, :header_content_thermal_responsive
    remove_column :fee_receipt_templates, :header_content_a5_portrait
  end
end
