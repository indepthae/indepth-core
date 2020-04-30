class CreateIdCardTemplates < ActiveRecord::Migration
  def self.up
    create_table :id_card_templates do |t|
      t.string :name
      t.integer :user_type
      t.string :serial_no
      t.integer :top_padding
      t.integer :right_padding
      t.integer :left_padding
      t.integer :bottom_padding
      t.string :front_background_image_file_name
      t.string :front_background_image_content_type
      t.integer :front_background_image_file_size
      t.datetime :front_background_image_updated_at
      t.string :include_back
      t.string :back_background_image_file_name
      t.string :back_background_image_content_type
      t.integer :back_background_image_file_size
      t.datetime :back_background_image_updated_at
      t.integer :template_resolutions_id
      t.integer :front_template_id
      t.integer :back_template_id
      t.integer :school_id
      t.timestamps
    end
    add_index :id_card_templates,[:school_id]
  end

  def self.down
    drop_table :id_card_templates
  end
end
