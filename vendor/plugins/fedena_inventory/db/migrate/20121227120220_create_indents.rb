class CreateIndents < ActiveRecord::Migration
  def self.up
    create_table :indents do |t|
      t.string :indent_no
      t.datetime :expected_date
      t.string :status
      t.boolean :is_deleted, :default => false
      t.text :description
      t.references :user
      t.references :store
      t.references :manager

      t.timestamps
    end
  end

  def self.down
    drop_table :indents
  end
end
