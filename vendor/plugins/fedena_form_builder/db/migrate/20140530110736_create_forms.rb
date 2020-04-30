class CreateForms < ActiveRecord::Migration
  def self.up
    create_table :forms do |t|
      t.integer :form_template_id
      t.string :name
      t.integer :user_id
      t.boolean :is_public, :default => true
      t.boolean :is_closed, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :forms
  end
end
