class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "model"
    end
  end

  def self.down
    drop_table :reports
  end
end
