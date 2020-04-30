class AddingShowInReportToDescriptiveIndicator < ActiveRecord::Migration
  def self.up
    add_column :descriptive_indicators,:show_in_report,:boolean,:default=>false
  end

  def self.down
    remove_column :descriptive_indicators,:show_in_report,:boolean
  end
end
