class CreateMessageTemplateContents < ActiveRecord::Migration
  def self.up
    create_table :message_template_contents do |t|
      t.text :content
      t.string :user_type
      t.references :message_template
      t.integer :school_id

      t.timestamps
    end
    add_index :message_template_contents,[:school_id]
  end

  def self.down
    drop_table :message_template_contents
  end
end
