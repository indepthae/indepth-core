class CustomTranslation < ActiveRecord::Base
  
  attr_accessor :term, :term_type, :default_value, :translate_options
  cattr_accessor :translate_options
  
  validates_presence_of :key, :translation
  
  TERMINOLOGIES = [:course, :courses, :batch, :batches, :subject, :subjects]
  
  GROUPED_TERMINOLOGIES = {:course => [{:small_case => :course}, {:small_case_plural => :courses}], 
    :batch => [{:small_case => :batch}, {:small_case_plural => :batches}], 
    :subject => [{:small_case => :subject}, {:small_case_plural => :subjects}]
  }
  
  DEFAULT_VALUES = {:cw_batch=>"batch", :cw_batch_capital=>"Batch", :cw_batches=>"batches", :cw_batches_capital=>"Batches",
    :cw_subject=>"subject", :cw_subject_capital=>"Subject", :cw_subjects=>"subjects", :cw_subjects_capital=>"Subjects"}
    
  class << self
  
    def make_options
      unless Configuration.custom_words_disabled?
        changes = all.inject({}) {|t, obj| t[obj.key.to_sym] = obj.translation; t}
        options = {}
        TERMINOLOGIES.each do |t|
          val= ((changes.keys.include? t) ? changes[t] : t("#{t}_terminology"))
          options["cw_#{t.to_s}".to_sym] = val
          options["cw_#{t.to_s}_capital".to_sym] = val.capitalize
        end
      else
        config_value = Configuration.get_config_value("InstitutionType")
        institution_type = (config_value.present? ? config_value : "hd")
        values = if(institution_type == "hd")
          {:cw_course_capital=>"Course", :cw_courses_capital=>"Courses", :cw_course=>"course", :cw_courses=>"courses" }
        else
          {:cw_course_capital=>"Class", :cw_courses_capital=>"Classes", :cw_course=>"class", :cw_courses=>"classes" }
        end
        options = DEFAULT_VALUES.merge(values)
      end
      return options
    end
    
    def make_form
      changes = all.inject({}) {|t, obj| t[obj.key.to_sym] = obj.translation; t}
      values = {}
      GROUPED_TERMINOLOGIES.each do |key, val|
        temp = {}
        val.each do |list|
          list.each do |type, v |
            val= ((changes.keys.include? v) ? changes[v] : t("#{v}_terminology"))
            temp[type] = {:key => v.to_s, :translation => val, :default_value => t("#{v}_terminology")}
          end
        end
        values[key] = temp
      end
      values
    end
    
    def store_cache
      current_school = MultiSchool.current_school
      Configuration.cache_it("translate_options_#{current_school.id}"){
        CustomTranslation.make_options 
      }
    end

    def flush_cache
      current_school = MultiSchool.current_school
      Configuration.uncache_it("translate_options_#{current_school.id}") 
    end
    
  end
  
end
