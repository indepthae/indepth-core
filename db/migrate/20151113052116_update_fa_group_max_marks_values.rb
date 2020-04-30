class UpdateFaGroupMaxMarksValues < ActiveRecord::Migration
  def self.up
    update <<-SQL
      update fa_groups set max_marks = 100.0 where fa_groups.id > 1
    SQL
  end

  def self.down
  end
end
