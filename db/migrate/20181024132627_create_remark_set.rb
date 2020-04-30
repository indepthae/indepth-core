class CreateRemarkSet < ActiveRecord::Migration
  def self.up
    create_table :remark_sets do |t|
      t.references :assessment_plan
      t.string :name
      t.string :target_type
      t.references :school
    end
  end

  def self.down
    drop_table :remark_sets
  end
end
