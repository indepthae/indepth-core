class CreateCustomTranslations < ActiveRecord::Migration
  def self.up
    create_table :custom_translations do |t|
      t.string :key
      t.string :translation

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_translations
  end
end
