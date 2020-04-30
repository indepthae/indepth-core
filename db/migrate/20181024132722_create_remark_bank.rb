class CreateRemarkBank < ActiveRecord::Migration
  def self.up
    create_table :remark_banks do |t|
      t.string :name
      t.references :school
    end
  end

  def self.down
    drop_table :remark_banks
  end
end
