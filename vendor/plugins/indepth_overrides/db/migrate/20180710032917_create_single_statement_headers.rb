class CreateSingleStatementHeaders < ActiveRecord::Migration
  def self.up
    create_table :single_statement_headers do |t|
	  t.integer :school_id
      t.string :logo_file_name
      t.string :logo_content_type
      t.string :logo_file_size
      t.boolean :is_empty
      t.string :title
      t.integer :space_height
      t.timestamps
    end
  end

  def self.down
    drop_table :single_statement_headers
  end
end
