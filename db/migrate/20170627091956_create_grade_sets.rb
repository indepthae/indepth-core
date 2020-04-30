class CreateGradeSets < ActiveRecord::Migration
  def self.up
    create_table :grade_sets do |t|
      t.string :name
      t.boolean :direct_grade, :default => true
      t.boolean :enable_credit_points, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :grade_sets
  end
end
