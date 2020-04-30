class CreateSchoolStats < ActiveRecord::Migration
  def self.up
    create_table :school_stats do |t|
      t.text :live_stats
      t.references :admin_user
      t.timestamps
    end
  end

  def self.down
    drop_table :school_stats
  end
end
