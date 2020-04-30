class CreateReportColumns < ActiveRecord::Migration
  def self.up
    create_table :report_columns do |t|
      t.integer  "report_id"
      t.string   "title"
      t.string   "method"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "report_columns", ["report_id"], :name => "index_report_columns_on_report_id"
  end

  def self.down
    add_index "report_columns", :name => "index_report_columns_on_report_id"
    drop_table :report_columns
  end
end
