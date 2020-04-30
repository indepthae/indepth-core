class CreateIcseWeightages < ActiveRecord::Migration
  def self.up
    create_table :icse_weightages do |t|
      t.string :name
      t.references :icse_exam_category
      t.decimal    :ea_weightage, :precision =>15, :scale => 2
      t.decimal    :ia_weightage, :precision =>15, :scale => 2
      t.boolean    :is_grade,:default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :icse_weightages
  end
end
