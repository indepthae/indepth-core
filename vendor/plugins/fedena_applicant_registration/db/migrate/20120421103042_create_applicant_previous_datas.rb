class CreateApplicantPreviousDatas < ActiveRecord::Migration
  def self.up
    create_table :applicant_previous_datas do |t|
      t.integer :school_id
      t.references :applicant
      t.string :last_attended_school
      t.string :qualifying_exam
      t.string :qualifying_exam_year
      t.string :qualifying_exam_roll
      t.string :qualifying_exam_final_score
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_guardians
  end
end
