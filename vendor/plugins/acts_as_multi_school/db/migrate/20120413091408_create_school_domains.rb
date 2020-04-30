class CreateSchoolDomains < ActiveRecord::Migration
  def self.up
    create_table :school_domains do |t|
      t.references :school
      t.string :domain

      t.timestamps
    end
  end

  def self.down
    drop_table :school_domains
  end
end
