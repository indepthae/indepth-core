class ChangeCountryIdToInt < ActiveRecord::Migration
  def self.up
	change_column :applicants, :country_id, :integer
  change_column :applicants, :nationality_id, :integer
  end

  def self.down
	change_column :applicants, :country_id, :string
  change_column :applicants, :nationality_id, :string
  end
end
