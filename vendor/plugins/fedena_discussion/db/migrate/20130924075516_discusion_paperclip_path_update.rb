class DiscusionPaperclipPathUpdate < ActiveRecord::Migration
  def self.up
    Rake::Task["fedena_discussion:update_plugins_paths"].execute
  end

  def self.down
  end
end
