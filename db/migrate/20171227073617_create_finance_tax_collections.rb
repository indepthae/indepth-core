class CreateFinanceTaxCollections < ActiveRecord::Migration
  def self.up
    create_table :tax_collections do |t|
      t.references :taxable_entity, :polymorphic => true, :null => false
      t.references :taxable_fee, :polymorphic => true, :null => false
      t.decimal :tax_amount, :precision => 10, :scale => 4, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :tax_collections
  end
end
