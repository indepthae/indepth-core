class CreateAssetFields < ActiveRecord::Migration
  def self.up
    create_table :asset_fields do |t|
      t.references :school_asset
      t.string :field_name
      t.string :field_type
      t.timestamps
    end
  end

  def self.down
    drop_table :asset_fields
  end
end
