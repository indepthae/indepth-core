class AddAssociationMethodToReportColumns < ActiveRecord::Migration
  def self.up
    add_column :report_columns, :association_method, :string
  end

  def self.down
    remove_column :report_columns, :association_method
  end
end
