class CreateGalleryCategoryPrivileges < ActiveRecord::Migration
  def self.up
    create_table :gallery_category_privileges do |t|
      t.references :gallery_category
      t.references :imageable, :polymorphic=>true

      t.timestamps
    end
  end

  def self.down
    drop_table :gallery_category_privileges
  end
end
