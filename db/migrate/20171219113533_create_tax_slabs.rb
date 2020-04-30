class CreateTaxSlabs < ActiveRecord::Migration
  def self.up
    create_table :tax_slabs do |t|
      t.string :name
      t.string :description
      t.decimal :rate, :precision =>10, :scale => 4

      t.timestamps
    end
  end

  def self.down
    drop_table :tax_slabs
  end
end
