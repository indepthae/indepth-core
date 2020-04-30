class CreateCbseCoScholasticSettings < ActiveRecord::Migration
  def self.up
    create_table :cbse_co_scholastic_settings do |t|
      t.integer :course_id
      t.integer :observation_id
      t.string  :code
      t.timestamps
    end
  end

  def self.down
    drop_table :cbse_co_scholastic_settings
  end
end
