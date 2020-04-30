class AddSchoolIdToCustomReports < ActiveRecord::Migration
  def self.up
    [:reports,:report_queries,:report_columns].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:reports,:report_queries,:report_columns].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
