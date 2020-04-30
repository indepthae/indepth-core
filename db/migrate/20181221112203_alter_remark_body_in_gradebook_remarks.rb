class AlterRemarkBodyInGradebookRemarks < ActiveRecord::Migration
  def self.up
    change_column :gradebook_remarks, :remark_body, :longtext
  end

  def self.down
    
  end
end
