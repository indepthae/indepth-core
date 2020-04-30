module MultiSchool

  module Write

    def self.included(base)
      base.send :belongs_to,:school
      School.send :has_many,base.table_name,:dependent=>:destroy
      base.send :before_validation,:insert_school_id
      base.send :validates_presence_of,:school_id      
    end

    def insert_school_id      
      self.school_id = MultiSchool.current_school.id  if MultiSchool.current_school
    end

  end

end
