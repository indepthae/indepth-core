class CreateIaGroups < ActiveRecord::Migration
  def self.up
    create_table :ia_groups do |t|
      t.string :name
      t.string :description
      t.references :icse_exam_category

      t.timestamps
    end
  end

  def self.down
    drop_table :ia_groups
  end
end
