class CreateDisciplineActions < ActiveRecord::Migration
  def self.up
    create_table :discipline_actions do |t|
      t.text :body
      t.string :remarks
      t.integer :school_id
      t.references :user
      t.references :discipline_complaint
      t.timestamps
    end
  end

  def self.down
    drop_table :discipline_actions
  end
end
