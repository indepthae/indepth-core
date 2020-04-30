class CreateIcseReports < ActiveRecord::Migration
  def self.up
    create_table :icse_reports do |t|
      t.references :batch
      t.references :exam
      t.references :student
      t.decimal :ia_score,:precision =>15, :scale => 2
      t.decimal :ea_score,:precision =>15, :scale => 2
      t.decimal :ia_mark,:precision =>15, :scale => 2
      t.decimal :ea_mark,:precision =>15, :scale => 2
      t.decimal :total_score,:precision =>15, :scale => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :icse_reports
  end
end
