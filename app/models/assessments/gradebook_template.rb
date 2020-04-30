class GradebookTemplate < ActiveRecord::Base
  require "#{Rails.root}/lib/gradebook/reports/template.rb"
  require "#{Rails.root}/lib/gradebook/reports/template_setting.rb"
  
  has_and_belongs_to_many :schools,:join_table => "gradebook_template_schools"
  validates_uniqueness_of :name,:case_sensitive => false
  
  serialize :template, Gradebook::Reports::Template
  
  class << self
    def add_template(template)
      temp = create(attribs(template))
      temp.schools = temp.fetch_schools(template)
      
      temp
    end
    
    def attribs(template)
      {
        :name => template.name,
        :file_checksum => template.config_checksum,
        :template => template,
        :is_common => !template.schools.present?
      }
    end
    
    def get_template(name)
      find_by_name(name).try(:template)
    end
    
    def available_templates
      find_by_sql("select gt.* from gradebook_templates gt inner join gradebook_template_schools gs on gs.gradebook_template_id=gt.id where gs.school_id in (#{[MultiSchool.current_school.id]}) and gt.is_active = true UNION ALL select * from gradebook_templates gt where gt.is_common = true and gt.is_active = true")
    end
  end
  
  def validate_and_update(template)
    unless template.config_checksum == self.file_checksum
      update_attributes(self.class.attribs(template))
      self.schools = fetch_schools(template)
    end
  end
  
  def fetch_schools(template)
    School.find_all_by_id template.schools
  end
  
end
