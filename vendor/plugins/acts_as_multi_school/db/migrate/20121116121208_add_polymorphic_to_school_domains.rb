class AddPolymorphicToSchoolDomains < ActiveRecord::Migration
  class SchoolDomain < ActiveRecord::Base
    def self.swap_school_ids
      all.each do |domain|
        domain.update_attributes(:linkable_type=>"School", :linkable_id=>domain.school_id)
      end
    end
  end
  def self.up
    add_column :school_domains, :linkable_id, :integer
    add_column :school_domains, :linkable_type, :string
    SchoolDomain.reset_column_information
    SchoolDomain.swap_school_ids
    remove_column :school_domains, :school_id
  end

  def self.down
    remove_column :school_domains, :linkable_type
    remove_column :school_domains, :linkable_id
    add_column :school_domains, :school_id, :integer
  end
end
