class CreateTallyExportConfigurations < ActiveRecord::Migration
  def self.up
    create_table :tally_export_configurations do |t|
      t.references :school
      t.string :config_key
      t.string :config_value
    end
  end

  def self.down
    drop_table :tally_export_configurations
  end
end
