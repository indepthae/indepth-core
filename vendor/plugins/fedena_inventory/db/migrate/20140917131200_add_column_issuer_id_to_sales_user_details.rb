class AddColumnIssuerIdToSalesUserDetails < ActiveRecord::Migration
  def self.up
    add_column :sales_user_details, :issuer_id, :integer
  end

  def self.down
    remove_column :sales_user_details, :issuer_id
  end
end
