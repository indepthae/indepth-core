#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class Configuration < ActiveRecord::Base
  xss_terminate :sanitize => [:config_value]
  STUDENT_ATTENDANCE_TYPE_OPTIONS = [["#{t('daily_text')}", "Daily"], ["#{t('subject_wise_text')}", "SubjectWise"]]
  ROLL_NUMBER_SORT_ORDER = {"0" => "first_name",
    "1" => "last_name",
    "2" => "admission_no"
  }
  after_save :reflect_receipt_changes
  before_save :flush_translation_options, :if => "config_key == 'InstitutionType'"
  before_update :flush_existing_cache
  
  @@cache = Rails.cache
  @@memcache_on = @@cache.is_a? ActiveSupport::Cache::MemCacheStore
  
  LOCALES = []
  Dir.glob("#{RAILS_ROOT}/config/locales/*.yml").each do |file|
    file.gsub!("#{RAILS_ROOT}/config/locales/", '')
    file.gsub!(".yml", '')
    LOCALES << file
  end

  def validate
    if self.config_key == "StudentAttendanceType"
      errors.add_to_base("#{t('student_attendance_type_should_be_one')} #{STUDENT_ATTENDANCE_TYPE_OPTIONS}") unless Configuration::STUDENT_ATTENDANCE_TYPE_OPTIONS.collect{|d| d[1] == self.config_value}.include?(true)
    elsif self.config_key == "InstitutionEmail"
      errors.add(self.config_key.titleize,"#{t('must_be_a_valid_email_address')}") if (config_value.present? and config_value.match(/^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,10}$/i) == nil) == true
    elsif self.config_key == "InstitutionWebsite"
      errors.add(self.config_key.titleize,"#{t('must_be_a_valid_web_address')}") if (config_value.present? and config_value.match(/^((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?(\/.*)?$/ix) == nil) == true  
    elsif self.config_key == "FeeReceiptNo"    
      errors.add_to_base("#{t('receipt_number_must_end_with_a_digit',{:receipt_no=>config_value})}") if (config_value.present? and config_value.strip.match(/(\d+)$/) == nil) == true
    end
  end

  def self.clear_school_cache(user)
    @@cache.delete("current_school_name#{user.id}")
  end
  
  class << self
    
    def cache_it (key, &block)
      if @@memcache_on
        @@cache.fetch(key){block.call}
      else
        block.call      
      end
    end
    
    def uncache_it (key)
      if (@@memcache_on and @@cache.exist?(key))
        @@cache.delete(key)
      else
        true
      end
    end
    
    def find_by_config_key(key)
      Configuration.cache_it(Configuration.fetch_model_cache_key(self,key)) { find(:first, :conditions=>{:config_key=>key}) }
    end
    
    def fetch_model_cache_key(key_name,key_value)
      [key_name.name.underscore,"/#{MultiSchool.current_school.id}/", key_value]
    end
    
    def clear_model_cache(key_name,key_value)
      Configuration.uncache_it(Configuration.fetch_model_cache_key(key_name,key_value))
    end
    
    def find_or_create_by_config_key(key)
      config_key_name = key
      if config_key_name.is_a? String
        Configuration.cache_it(Configuration.fetch_model_cache_key(self,config_key_name)) { find(:first, :conditions=>{:config_key=>config_key_name}) || create(:config_key=>config_key_name) }
      else
        super(config_key_name)
      end
    end
    
    def find_all_by_config_key(key)
      Configuration.cache_it(Configuration.fetch_model_cache_key(self,key)) { find(:all, :conditions=>{:config_key=>key}) }
    end
    
    def find_by_config_value(key)
      Configuration.cache_it(Configuration.fetch_model_cache_key(self,key)) { find(:first, :conditions=>{:config_value=>key}) }
    end

    def roll_number_sort_order
      sort_order = Configuration.get_config_value('RollNumberSortOrder')
      ROLL_NUMBER_SORT_ORDER[sort_order]
    end

    def enabled_roll_number?
      Configuration.get_config_value('EnableRollNumber') == "1" ? true : false
    end

    def get_school_details
      institute_name = Configuration.get_config_value('InstitutionName')
      institute_address = Configuration.get_config_value('InstitutionAddress')
      institute_phone = Configuration.get_config_value('InstitutionPhoneNo')
      institute_language = Configuration.get_config_value('Locale')
      institute_currency = Configuration.currency
      institute_time_zone = TimeZone.find_by_id(Configuration.get_config_value('TimeZone')).try(:code)
      [institute_name,institute_address,institute_phone,institute_language,institute_currency,institute_time_zone]
    end

    def get_config_value(key)
      c = find_by_config_key(key)
      c.nil? ? nil : c.config_value
    end
    def get_sort_order_config_value 
      config = Configuration.find_or_create_by_config_key('StudentSortMethod')
      if config.config_value.nil?
        config = Configuration.set_value('StudentSortMethod', "first_name")
      end
      return config
    end
    def get_sort_order
      config = get_sort_order_config_value
      sort_order = "first_name ASC" if config.config_value == "first_name"
      sort_order = "last_name ASC" if config.config_value == "last_name"
      sort_order = "soundex(admission_no),length(admission_no),admission_no ASC" if config.config_value == "admission_no"
      sort_order = "soundex(students.roll_number),length(students.roll_number),students.roll_number ASC" if config.config_value == "roll_number"
      return sort_order
    end

    def save_institution_logo(upload)
      directory, filename = "#{RAILS_ROOT}/public/uploads/image", 'institute_logo.jpg'
      path = File.join(directory, filename) # create the file path
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) } # write the file
    end

    def available_modules
      modules = find_all_by_config_key('AvailableModules')
      modules.map(&:config_value)
    end

    def set_config_values(values_hash)
      errors=[]
      values_hash.each_pair do |key,value|
        ret_val=set_value(key.to_s.camelize, value)
        errors.push(ret_val) if ret_val.errors.present?
      end
      if errors.length > 0
        return errors
      else
        return []
      end
    end

    def set_value(key, value)
      #config = find_by_config_key(key)
      config = find(:first, :conditions=>{:config_key=>key})
      config.nil? ?
        Configuration.create(:config_key => key, :config_value => value) :
        config.update_attributes(:config_value => value) == true ? (config) : (config)
    end

    def get_multiple_configs_as_hash(keys)
      conf_hash = {}
      keys.each { |k| conf_hash[k.underscore.to_sym] = get_config_value(k) }
      conf_hash
    end

    def get_grading_types
      grading_types = Course::GRADINGTYPES
      types= all(:conditions=>{:config_key=>grading_types.values, :config_value=>"1"},:group=>:config_key)
      grading_types.keys.select{|k| types.collect(&:config_key).map{|s| s.upcase}.include? grading_types[k]}
    end

    def default_country
      default_country_value = self.find_by_config_key('DefaultCountry').try(:config_value).to_i
      return default_country_value
    end

    def set_grading_types(updates)
      #expects an array of integers types
      grading_types = Course::GRADINGTYPES
      deletions = grading_types.keys - updates
      updates.each do |t|
        find_or_create_by_config_key(grading_types[t]).update_attribute(:config_value, 1)
      end
      deletions.each do |t|
        find_or_create_by_config_key(grading_types[t]).update_attribute(:config_value, 0)
      end
    end

    def default_time_zone_present_time
      server_time = Time.now
      server_time_to_gmt = server_time.getgm
      local_tzone_time = server_time
      time_zone = Configuration.find_by_config_key("TimeZone")
      unless time_zone.nil?
        unless time_zone.config_value.nil?
          zone = TimeZone.find_by_id(time_zone.config_value)
          if zone.present?
            if zone.difference_type=="+"
              local_tzone_time = server_time_to_gmt + zone.time_difference
            else
              local_tzone_time = server_time_to_gmt - zone.time_difference
            end
          end
        end
      end
      return local_tzone_time
    end

    def cce_enabled?
      get_config_value("CCE") == "1"
    end

    def has_gpa?
      get_config_value("GPA") == "1"
    end

    def has_cwa?
      get_config_value("CWA") == "1"
    end

    def icse_enabled?
      get_config_value("Icse") == "1"
    end

    def cce_enabled?
      get_config_value("CCE") == "1"
    end

    def number_decimal_precision value
      precision_count = Configuration.get_config_value('PrecisionCount')
      precision = precision_count.to_i < 2 ? 2 : precision_count.to_i
      precision
    end

    def currency
      currency_symbol = Configuration.find_by_config_key("CurrencyType").config_value
      return currency_symbol if currency_symbol.present?

      country_currency_code = default_currency
      return '$' unless country_currency_code.present?

      currency_code = NumberToWord::CURRENCY_DETAILS[country_currency_code]
      return '$' unless currency_code.present?
      return (currency_code['symbol'] || '$')
    end

    def ignore_lop
      ignore = Configuration.find_by_config_key("IgnoreLopResetLeave")
      ignore ?  ignore : new(:config_key => "IgnoreLopResetLeave", :config_value => "false")
    end

    def gross_based_payroll
      payroll_settings = Configuration.find_by_config_key("GrossBasedPayroll")
      payroll_settings ?  payroll_settings : new(:config_key => "GrossBasedPayroll", :config_value => "true")
    end
    
    def to_enable_round_off
      payroll_settings = Configuration.find_by_config_key("EnableRoundOff")
      payroll_settings ?  payroll_settings : new(:config_key => "EnableRoundOff", :config_value => "0")
    end
    
    def get_rounding_off_value
      payroll_settings = Configuration.find_by_config_key("ROUNDOFF")
      payroll_settings ?  payroll_settings : new(:config_key => "ROUNDOFF", :config_value => "2")
    end

    def is_gross_based_payroll
      gross_based_payroll.config_value == "true"
    end
    
    def default_currency
      default_country_currency = Configuration.get_config_value('CurrencyCode')

      if !default_country_currency.present? or (default_country_currency.present? and !NumberToWord::CURRENCY_DETAILS[default_country_currency].present?)
        default_country = Configuration.default_country
        default_country_currency = Country.find_by_id(default_country).try(:currency_code)
      end

      return default_country_currency
    end
    
    def custom_words_disabled?
      get_config_value("disable_custom_words") == "1" ? true : false
    end
    
    def advance_fee_payment_enabled?
      get_config_value("AdvanceFeePaymentForStudent") == "1" ? true : false
    end
    
    def receipt_number_disabled?
      get_config_value("DisableReceiptNumber") == "0" ? true : false
    end
    
    def is_fine_settings_enabled?
      get_config_value("EnableFineSettings") == "1" ? true : false
    end
    
    def is_batch_date_attendance_config?
      get_config_value("AttendanceCalculation") == "BatchDate"
    end

    def precision_count
      self.find_by_config_key("PrecisionCount").config_value
    end

    def school_details_hash
      details = {}
      details[:institution_name] = get_config_value('InstitutionName')
      details[:institution_address] = get_config_value('InstitutionAddress')
      details[:institution_phone] = get_config_value('InstitutionPhoneNo')
      details[:institution_website] = get_config_value('InstitutionWebsite')
      return details
    end
    
  end

  private

  def reflect_receipt_changes
    FeeReceiptLock.clear_cache
  end

  def flush_existing_cache
    Configuration.clear_model_cache(self.class,self.config_key)
  end
  
  def flush_translation_options
    CustomTranslation.flush_cache
  end
  
end

#   Configuration table entries
#
#   StudentAttendanceType  => Daily | SubjectWise
#   CurrencyType           => Rs, $, E, ...
#   ExamResultType         => Marks | Grades | MarksAndGrades
#   InstitutionName        => name of the school or college
# => ReceiptPrinterType         => Receipt Printer type
# => ReceiptPrinterFormat       =>  Receipt Printer Format
# => ReceiptPrinterHeaderType   =>  Receipt printer header type
# => ReceiptPrinterHeaderHeight =>  Receipt Printer Header height
