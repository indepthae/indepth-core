class CreateSalesUserDetails < ActiveRecord::Migration
  def self.up
    create_table :sales_user_details do |t|
      t.references :user
      t.string :username
      t.string :address
      t.references :batch
      t.references :invoice
      t.string :invoice_type
      t.timestamps
    end
  end

  def self.down
    drop_table :sales_user_details
  end
end
