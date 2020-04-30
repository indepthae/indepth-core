class CreateFinancialYears < ActiveRecord::Migration
  def self.up
    create_table :financial_years do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.integer :school_id
      t.boolean :is_active, :default => 0

      t.timestamps
    end

    add_index :financial_years, :school_id
  end

  def self.down
    drop_table :financial_years
  end
end
