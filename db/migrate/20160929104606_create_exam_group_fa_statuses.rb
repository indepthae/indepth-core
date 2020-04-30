class CreateExamGroupFaStatuses < ActiveRecord::Migration
  def self.up
    create_table :exam_group_fa_statuses do |t|
      t.integer :exam_group_id
      t.string :fa_group
      t.boolean :send_or_resend_sms, :default=>false 
      t.timestamps
    end
  end

  def self.down
    drop_table :exam_group_fa_statuses
  end
end
