class CreateDisciplineComments < ActiveRecord::Migration
  def self.up
    create_table :discipline_comments do |t|
      t.text :body
      t.integer :commentable_id
      t.string :commentable_type
      t.integer :school_id
      t.references :user

      t.timestamps
    end
   
  end

  def self.down
    drop_table :discipline_comments
  end
end
