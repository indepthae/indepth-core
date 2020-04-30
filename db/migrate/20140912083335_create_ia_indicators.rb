class CreateIaIndicators < ActiveRecord::Migration
  def self.up
    create_table :ia_indicators do |t|
      t.string :name
      t.decimal :max_mark, :precision =>15, :scale => 2
      t.string :indicator
      t.references :ia_group

      t.timestamps
    end
  end

  def self.down
    drop_table :ia_indicators
  end
end
