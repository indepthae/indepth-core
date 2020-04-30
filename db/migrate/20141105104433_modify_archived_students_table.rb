class ModifyArchivedStudentsTable < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :former_has_paid_fees,:boolean
  end

  def self.down
    remove_column :archived_students, :former_has_paid_fees
  end
end
