class AddCurrencyToCountry < ActiveRecord::Migration
  def self.up
    add_column :countries, :code, :string
    add_column :countries, :currency_code, :string
  end

  def self.down
    remove_column :countries, :code
    remove_column :countries, :currency_code
  end
end
