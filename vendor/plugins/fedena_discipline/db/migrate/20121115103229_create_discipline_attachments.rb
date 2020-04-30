class CreateDisciplineAttachments < ActiveRecord::Migration
  def self.up
    create_table :discipline_attachments do |t|
      t.integer :school_id
      t.references :discipline_participation
      

      t.timestamps
    end
  end

  def self.down
    drop_table :discipline_attachments
  end
end
