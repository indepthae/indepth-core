class AddRegionalNameToCountries < ActiveRecord::Migration
  def self.up
    add_column :countries, :regional_name, :string
  end

  def self.down
    remove_column :countries, :regional_name
  end
end