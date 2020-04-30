class CreateExports < ActiveRecord::Migration
  def self.up
    create_table :exports do |t|
       t.text   :structure
       t.string :name
       t.string :model
       t.text   :associated_columns
       t.text   :join_columns
       t.timestamps
     end
  end

  def self.down
    drop_table :exports
  end
end
