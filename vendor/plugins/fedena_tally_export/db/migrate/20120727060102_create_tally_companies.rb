class CreateTallyCompanies < ActiveRecord::Migration
  def self.up
    create_table :tally_companies do |t|
      t.references :school
      t.string :company_name

      t.timestamps
    end
  end

  def self.down
    drop_table :tally_companies
  end
end
