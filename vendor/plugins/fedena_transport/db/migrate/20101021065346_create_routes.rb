class CreateRoutes < ActiveRecord::Migration
  def self.up
    create_table :routes do |t|
      t.string     :destination
      t.string     :cost
      t.references :main_route
      t.timestamps
    end
  end

  def self.down
    drop_table :routes
  end
end
