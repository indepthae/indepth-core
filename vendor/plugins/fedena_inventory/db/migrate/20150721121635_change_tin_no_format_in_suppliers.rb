class ChangeTinNoFormatInSuppliers < ActiveRecord::Migration
  def self.up
    change_column :suppliers, :tin_no,  :string
  end

  def self.down
    change_column :suppliers, :tin_no,  :integer
  end
end
