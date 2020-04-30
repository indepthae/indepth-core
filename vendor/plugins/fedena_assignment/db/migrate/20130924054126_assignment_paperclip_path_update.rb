class AssignmentPaperclipPathUpdate < ActiveRecord::Migration
  def self.up
    Rake::Task["fedena_assignment:update_plugins_paths"].execute
  end

  def self.down
  end
end
