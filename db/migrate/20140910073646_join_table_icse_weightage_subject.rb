class JoinTableIcseWeightageSubject < ActiveRecord::Migration
  def self.up
    create_table :icse_weightages_subjects, :id => false do |t|
      t.references :icse_weightage
      t.references :subject
    end
    add_index :icse_weightages_subjects, [:icse_weightage_id, :subject_id],:name => :index_by_fields
  end

  def self.down
    drop_table :icse_weightages_subjects
  end
end
