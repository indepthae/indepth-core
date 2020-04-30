class AddDigestToMasterDiscountReport < ActiveRecord::Migration
  def self.up
    add_column :master_discount_reports, :digest, :string, :null => false

    add_index :master_discount_reports, :digest, :unique => true
  end

  def self.down
    remove_index :master_discount_reports, :digest

    remove_column :master_discount_reports, :digest
  end
end
