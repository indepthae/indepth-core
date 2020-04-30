class CreateWardens < ActiveRecord::Migration
  def self.up
    create_table :wardens do |t|
      t.references  :hostel
      t.references  :employee
      t.timestamps
    end
  end

  def self.down
    drop_table :wardens
  end
end
