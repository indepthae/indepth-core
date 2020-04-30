class AddingIndicesToMultipleCceRelatedTables < ActiveRecord::Migration
  def self.up
    add_index :cce_reports,:observable_id
    add_index :cce_reports,:observable_type
    add_index :cce_reports,:student_id
    add_index :cce_reports,:grade_string
  end

  def self.down
    remove_index :cce_reports,:observable_id
    remove_index :cce_reports,:observable_type
    remove_index :cce_reports,:student_id
    remove_index :cce_reports,:grade_string
  end
end
