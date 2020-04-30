class CreateOnlineExamGroups < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups do |t|
      t.string    :name
      t.date  :start_date
      t.date  :end_date
      t.decimal   :maximum_time, :precision => 7, :scale=>2
      t.decimal   :pass_percentage, :precision => 6, :scale=>2
      t.integer   :option_count
      t.references :batch
      t.boolean   :is_deleted  , :default=>0
      t.boolean   :is_published  , :default=>0
      t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_groups
  end
end
