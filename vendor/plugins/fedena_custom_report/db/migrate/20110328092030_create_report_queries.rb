class CreateReportQueries < ActiveRecord::Migration
  def self.up
    create_table :report_queries do |t|
      t.integer  "report_id"
      t.string   "table_name"
      t.string   "column_name"
      t.string   "criteria"
      t.text     "query"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "column_type"
    end
    add_index "report_queries", ["report_id"], :name => "index_report_queries_on_report_id"
  end

  def self.down
    remove_index :report_queries, :name => "index_report_queries_on_report_id"
    drop_table :report_queries
  end
end
