class AddIndexOnMenuLinks < ActiveRecord::Migration
  def self.up
    add_index :user_menu_links , [:menu_link_id,:user_id], :name => :on_user_and_link
  end

  def self.down
    remove_index :user_menu_links , :on_user_and_link
  end
end
