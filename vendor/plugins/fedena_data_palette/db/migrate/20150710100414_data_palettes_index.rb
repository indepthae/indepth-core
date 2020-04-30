class DataPalettesIndex < ActiveRecord::Migration
  def self.up
    if (ActiveRecord::Base.connection.execute("SHOW INDEX FROM user_palettes WHERE Key_name = 'index_user_palettes_on_user_id_and_palette_id';").all_hashes.empty?)
      add_index :user_palettes, [:user_id,:palette_id]
    end
    if (ActiveRecord::Base.connection.execute("SHOW INDEX FROM palettes WHERE Column_name = 'name';").all_hashes.empty?)
      add_index :palettes, :name
    end
  end

  def self.down

  end
end
