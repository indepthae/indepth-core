class CreateAssetFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :asset_field_options do |t|
      t.references :asset_field
      t.string :option
      t.timestamps
    end
  end

  def self.down
    drop_table :asset_field_options
  end
end