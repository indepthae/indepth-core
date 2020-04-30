class CreateGrades < ActiveRecord::Migration
  def self.up
    create_table :grades do |t|
      t.string :name
      t.references :grade_set
      t.decimal :minimum_marks, :precision => 10, :scale => 2
      t.decimal :credit_points, :precision => 10, :scale => 2
      t.boolean :pass_criteria, :default => true
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :grades
  end
end
