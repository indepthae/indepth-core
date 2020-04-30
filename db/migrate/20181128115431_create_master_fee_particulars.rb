class CreateMasterFeeParticulars < ActiveRecord::Migration
  def self.up
    create_table :master_fee_particulars do |t|
      t.string :name, :null => false
      t.string :description
      t.string :particular_type, :null => false
      t.integer :school_id, :null => false

      t.timestamps
    end

    add_index :master_fee_particulars, :school_id
  end

  def self.down
    drop_table :master_fee_particulars
  end
end
