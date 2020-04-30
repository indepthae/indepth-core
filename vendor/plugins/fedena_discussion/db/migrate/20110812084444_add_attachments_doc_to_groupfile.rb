class AddAttachmentsDocToGroupfile < ActiveRecord::Migration
  def self.up
    add_column :group_files, :doc_file_name, :string
    add_column :group_files, :doc_content_type, :string
    add_column :group_files, :doc_file_size, :integer
    add_column :group_files, :doc_updated_at, :datetime
  end

  def self.down
    remove_column :group_files, :doc_file_name
    remove_column :group_files, :doc_content_type
    remove_column :group_files, :doc_file_size
    remove_column :group_files, :doc_updated_at
  end
end
