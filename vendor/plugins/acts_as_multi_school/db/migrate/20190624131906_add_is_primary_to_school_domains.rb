class AddIsPrimaryToSchoolDomains < ActiveRecord::Migration
  def self.up
    add_column :school_domains, :is_primary, :boolean, :default => false
  end

  def self.down
    remove_column :school_domains, :is_primary
  end
end
