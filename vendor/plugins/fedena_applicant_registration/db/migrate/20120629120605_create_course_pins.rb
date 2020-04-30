class CreateCoursePins < ActiveRecord::Migration
  def self.up
    create_table :course_pins do |t|
      t.boolean :is_pin_enabled
      t.references :course

      t.timestamps
    end
  end

  def self.down
    drop_table :course_pins
  end
end
