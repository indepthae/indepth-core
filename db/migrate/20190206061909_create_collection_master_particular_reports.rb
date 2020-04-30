class CreateCollectionMasterParticularReports < ActiveRecord::Migration
  def self.up
    create_table :collection_master_particular_reports do |t|
      t.integer :financial_year_id
      t.integer :student_id, :null => false
      t.integer :collection_id, :null => false
      t.string :collection_type, :null => false
      t.integer :master_fee_particular_id, :null => false
      t.decimal :actual_amount, :default => 0, :precision => 15, :scale => 4
      t.decimal :discount_amount, :default => 0, :precision => 15, :scale => 4
      t.decimal :tax_amount, :default => 0, :precision => 15, :scale => 4
      t.decimal :amount, :default => 0, :precision => 15, :scale => 4
      t.integer :digest, :null => false
      t.integer :school_id, :null => false

      t.timestamps
    end

    add_index :collection_master_particular_reports, :school_id, :name => "index_by_school_id"
    add_index :collection_master_particular_reports, :digest, :name => "index_by_digest", :unique => true
  end

  def self.down
    remove_index :collection_master_particular_reports, :digest
    remove_index :collection_master_particular_reports, :school_id

    drop_table :collection_master_particular_reports
  end
end
