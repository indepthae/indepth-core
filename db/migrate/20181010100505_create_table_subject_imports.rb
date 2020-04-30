class CreateTableSubjectImports < ActiveRecord::Migration
  def self.up
    create_table :subject_imports do |t|
      t.references :course
      t.text :parameters
      t.text :last_error
      t.integer :status
      
      t.timestamps
    end
  end

  def self.down
    drop_table :subject_imports
  end
end
