class CreateAppFrames < ActiveRecord::Migration
  def self.up
    create_table :app_frames do |t|
      t.string :name
      t.string :link
      t.string :client_id
      t.text :privilege_list

      t.timestamps
    end
  end

  def self.down
    drop_table :app_frames
  end
end
