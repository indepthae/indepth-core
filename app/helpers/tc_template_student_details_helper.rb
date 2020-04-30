module TcTemplateStudentDetailsHelper
  
  def set_system_value_criteria(system_value)
    keys=TcTemplateVersion::SYSTEM_FIELDS.select{|key,value|
      if value[:field] == system_value
        return t(value[:name])
      end
  }

  end
 
  def set_custom_value_criteria(custom_value)
    keys=TcTemplateVersion::CUSTOM_FIELDS.select{|key,value|
      if value[:field] == custom_value
       return value[:name]
      end
  }

  end

end
