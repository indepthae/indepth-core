class CreateTableSubjectGroups < ActiveRecord::Migration
  def self.up
    create_table :subject_groups do |t|
      t.string  :name
      t.references :course
      t.timestamps
    end
  end

  def self.down
    drop_table :subject_groups
  end
end
