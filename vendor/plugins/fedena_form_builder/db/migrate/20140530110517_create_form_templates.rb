class CreateFormTemplates < ActiveRecord::Migration
  def self.up
    create_table :form_templates do |t|
      t.string :name
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :form_templates
  end
end
