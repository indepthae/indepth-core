class CreatePlacementevents < ActiveRecord::Migration
  def self.up
    create_table :placementevents do |t|
      t.string :title
      t.string :company
      t.string :place
      t.text :description
      t.boolean :is_active ,:default=>true
      t.datetime :date

      t.timestamps
    end
  end

  def self.down
    drop_table :placementevents
  end
end
