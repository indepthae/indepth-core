class ChangeDataTypeOfRemarkBody < ActiveRecord::Migration
  def self.up
    change_column :remarks, :remark_body, :text
  end

  def self.down
  end
end
