class CreateAssetEntries < ActiveRecord::Migration
  def self.up
    create_table :asset_entries do |t|
      t.references :asset_field
      t.text :dynamic_attributes
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :asset_entries
  end
end
