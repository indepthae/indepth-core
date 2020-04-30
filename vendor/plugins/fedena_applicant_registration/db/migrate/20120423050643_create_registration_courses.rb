class CreateRegistrationCourses < ActiveRecord::Migration
  def self.up
    create_table :registration_courses do |t|
      t.integer :school_id
      t.references :course
      t.integer :minimum_score
      t.boolean :is_active
      t.float   :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :registration_courses
  end
end
