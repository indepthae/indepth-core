class CreateDisciplineParticipations < ActiveRecord::Migration
  def self.up
    create_table :discipline_participations do |t|
      t.string :type
      t.boolean :action_taken
      t.integer :school_id
      t.references :user
      t.references :discipline_complaint

      t.timestamps
    end
  end

  def self.down
    drop_table :discipline_participations
  end
end
