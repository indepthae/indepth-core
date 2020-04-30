class AddColumnAcademicYearIdBatches < ActiveRecord::Migration
  def self.up
    add_column :batches, :academic_year_id, :integer
  end

  def self.down
    remove_column :batches, :academic_year_id
  end
end
