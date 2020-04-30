class CreateSchoolAssets < ActiveRecord::Migration
  def self.up
    create_table :school_assets do |t|
      t.string :asset_name
      t.string :asset_description
      t.timestamps
    end
  end

  def self.down
    drop_table :school_assets
  end
end
