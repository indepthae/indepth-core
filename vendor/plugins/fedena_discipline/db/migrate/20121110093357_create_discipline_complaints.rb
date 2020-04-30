class CreateDisciplineComplaints < ActiveRecord::Migration
  def self.up
    create_table :discipline_complaints do |t|
      t.string :subject
      t.text :body
      t.date :trial_date
      t.integer :school_id
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :discipline_complaints
  end
end
