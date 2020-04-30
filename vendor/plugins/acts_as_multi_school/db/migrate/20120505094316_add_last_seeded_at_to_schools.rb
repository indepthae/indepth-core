class AddLastSeededAtToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :last_seeded_at, :datetime
  end

  def self.down
    remove_column :schools, :last_seeded_at
  end
end
