class CreateTaxAssignments < ActiveRecord::Migration
  def self.up
    create_table :tax_assignments do |t|
      t.references :taxable, :polymorphic => true, :null => false      
      t.references :tax_slab, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :tax_assignments
  end
end
