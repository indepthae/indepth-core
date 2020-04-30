class CreateEiopSettings < ActiveRecord::Migration
  def self.up
    create_table :eiop_settings do |t|
      t.integer :course_id
      t.string :grade_point
      t.text :pass_text
      t.text :eiop_text
      t.timestamps
    end
  end

  def self.down
    drop_table :eiop_settings
  end
end
