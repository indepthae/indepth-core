class CreateCertificateTemplates < ActiveRecord::Migration
  def self.up
    create_table :certificate_templates do |t|
      t.string :name
      t.integer :user_type
      t.boolean :manual_serial_no
      t.string :serial_no_prefix
      t.references :base_template
      t.integer :top_padding
      t.integer :right_padding
      t.integer :left_padding
      t.integer :bottom_padding
      t.boolean :include_header
      t.string :background_image_file_name
      t.string :background_image_content_type
      t.integer :background_image_file_size
      t.datetime :background_image_updated_at
      t.references :template_resolutions
      t.integer :school_id

      t.timestamps
    end
      add_index :certificate_templates,[:school_id]
  end

  def self.down
    drop_table :certificate_templates
  end
end
