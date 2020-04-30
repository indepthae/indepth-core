class CreateAssessmentDate < ActiveRecord::Migration
  def self.up
    create_table :assessment_dates do |t|
      t.references :batch
      t.references :assessment_group
      t.date :start_date
      t.date :end_date
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_dates
  end
end
