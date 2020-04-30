class AddSchoolIdToDiscussions < ActiveRecord::Migration
  def self.up
    [:groups,:group_members,:group_files,:group_posts,:group_post_comments].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:groups,:group_members,:group_files,:group_posts,:group_post_comments].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
