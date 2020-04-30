class AddColumnsToMasterParticularReport < ActiveRecord::Migration
  def self.up
    add_column :master_particular_reports, :tax_amount, :decimal, :precision => 15, :scale => 4, :default => 0
    add_column :master_particular_reports, :discount_amount, :decimal, :precision => 15, :scale => 4, :default => 0
    add_column :master_particular_reports, :digest, :string, :null => false

    add_index :master_particular_reports, :digest, :unique => true
  end

  def self.down
    remove_index :master_particular_reports, :digest

    remove_column :master_particular_reports, :digest, :string
    remove_column :master_particular_reports, :discount_amount
    remove_column :master_particular_reports, :tax_amount
  end
end
