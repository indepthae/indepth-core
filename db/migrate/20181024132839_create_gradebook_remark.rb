class CreateGradebookRemark < ActiveRecord::Migration
  def self.up
    create_table :gradebook_remarks do |t|
      t.references :student
      t.references :batch
      t.string :remark_body
      t.integer :reportable_id
      t.string :reportable_type
      t.integer :remarkable_id
      t.string :remarkable_type
      t.references :school
    end
  end

  def self.down
    drop_table :gradebook_remarks
  end
end
