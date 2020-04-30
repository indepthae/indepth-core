module SchoolsHelper
  def set_domain(school_group,host)
#    school_group.class.to_s == "MultiSchoolGroup" ? "#{host}" : "#{MultiSchool.default_domain}"
    school_group.whitelabel_setting && school_group.whitelabel_setting.settings_to_sym[:company_url].present? ? school_group.whitelabel_setting.settings_to_sym[:company_url].delete(" ").gsub(/http:\/\//,"") : school_group.class.to_s == "MultiSchoolGroup" ? "#{host}" : "#{MultiSchool.default_domain}"
  end
  
  class << self
    def format_sms_settings_hash(hash)
      new_hash = Hash.new
      new_hash['sms_settings'] =  hash['sms_settings'].to_hash
      new_hash['parameter_mappings'] =  hash['parameter_mappings'].to_hash
      new_hash['additional_parameters'] = hash['additional_parameters'].gsub(" ", "") unless hash['additional_parameters'].blank?
      return new_hash
    end

   
  end
end
