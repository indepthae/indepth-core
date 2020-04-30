class ChangeDatatypeOfYearInPreviousData < ActiveRecord::Migration
  def self.up
    change_column :student_previous_datas, :year, :string
  end

  def self.down
    change_column :student_previous_datas, :year, :date
  end
end
