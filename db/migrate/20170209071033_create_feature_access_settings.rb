class CreateFeatureAccessSettings < ActiveRecord::Migration
  def self.up
    create_table :feature_access_settings do |t|
      t.string :feature_name
      t.boolean :parent_can_access, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :feature_access_settings
  end
end
