class CreateIaCalculations < ActiveRecord::Migration
  def self.up
    create_table :ia_calculations do |t|
      t.string :formula
      t.references :ia_group

      t.timestamps
    end
  end

  def self.down
    drop_table :ia_calculations
  end
end
