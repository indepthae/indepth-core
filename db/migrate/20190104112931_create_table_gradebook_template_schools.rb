class CreateTableGradebookTemplateSchools < ActiveRecord::Migration
  def self.up
    create_table :gradebook_template_schools, :id => false do |t|
      t.references :gradebook_template
      t.references :school
    end
    add_index :gradebook_template_schools, [:gradebook_template_id, :school_id], :name => 'index_on_tmpl_school'
  end

  def self.down
    drop_table :gradebook_template_schools
  end
end
