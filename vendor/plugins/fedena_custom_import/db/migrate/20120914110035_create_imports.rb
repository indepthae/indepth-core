class CreateImports < ActiveRecord::Migration
  def self.up
    create_table :imports do |t|
      t.references :export
      t.string     :status
      t.timestamps
    end
  end

  def self.down
    drop_table :imports
  end
end
