class CreateApplicationInstructions < ActiveRecord::Migration
  def self.up
    create_table :application_instructions do |t|
      t.integer :registration_course_id
      t.text :description
      t.boolean :skip_instructions, :default=>false
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :application_instructions
  end
end
