class AddIndexToMessageTemplate < ActiveRecord::Migration
  def self.up
    add_index :message_template_contents, :user_type, :name => "index_by_user_type"
  end

  def self.down
    remove_index :message_template_contents,  :name => "index_by_user_type"
  end
end