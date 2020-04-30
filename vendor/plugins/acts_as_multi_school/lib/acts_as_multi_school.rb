require 'multischool/read'
require 'multischool/write'
require 'multischool/class_initializer'
require 'multischool/exceptions'
require 'multischool/delayed_job'

module MultiSchool

  TLD_SIZES = {:development => 1, :test => 0, :production =>2}
  
  class << self
    attr_accessor :current_school
    attr_accessor :current_school_group
  end

  def self.default_domain
    if RAILS_ENV == "production"
      self.multischool_settings["domain"]
    else
      "lvh.me"
    end
  end

  def self.core_multi_school_models
    YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")["multi_school_models"]
  end
  
  def self.multi_school_models
    models_from_yml=YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")["multi_school_models"]
    models_from_plugin=FedenaPlugin::MULTI_SCHOOL_MODELS.flatten
    models_from_yml + models_from_plugin
  end

  def self.core_general_models
    YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")["general_models"]
  end

  def self.general_models
    models_from_plugin=FedenaPlugin::GENERAL_MODELS.flatten
    core_general_models + models_from_plugin
  end

  def self.system_models
    models_from_yml=YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")["multi_school_system_models"]
    models_from_yml
  end

  def self.seed_models
    models_from_yml=YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")["seed_models"]
    models_from_yml
  end

  def self.setup_multi_school_for_models(klasses)
    klasses.each do |klass_name|
      klass = klass_name.constantize
      klass.send :acts_as_multi_school
    end
  end
  
  def self.setup_multi_school_for_classes(klasses)
    klasses.each do |klass_name|
      klass = klass_name.constantize
      klass.send :extend, ClassMethods
      klass.send(:acts_as_multi_school, {:read => false, :write => false, :type=>'class'})
    end
  end

  def self.setup_multi_school_from_yml
    models_hash=YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")
    classes_hash=YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_classes.yml")
    setup_multi_school_for_models(models_hash["multi_school_models"]) unless models_hash["multi_school_models"].nil?
    setup_multi_school_for_classes(classes_hash["multi_school_classes"]) unless classes_hash["multi_school_classes"].nil?
  end

  def self.included(base)
    base.metaclass::VALID_FIND_OPTIONS << :skip_multischool
    ActiveRecord::Calculations::CALCULATIONS_OPTIONS<< :skip_multischool
    base.send :extend, ClassMethods
  end

  def self.configure_subdomain
    settings = YAML.load_file(File.dirname(__FILE__)+"/../config/multischool_settings.yml") if File.exists?(File.dirname(__FILE__)+"/../config/multischool_settings.yml")
    tld_sizes = settings['settings']['tld_sizes'] if settings && settings['settings']['tld_sizes'].present?
    if tld_sizes.present?
      custom_tld_sizes = {
        :development => (tld_sizes['development'].present?) ? tld_sizes['development'].to_i : TLD_SIZES[:development],
        :test => (tld_sizes['test'].present?) ? tld_sizes['test'].to_i : TLD_SIZES[:test],
        :production => (tld_sizes['production'].present?) ? tld_sizes['production'].to_i : TLD_SIZES[:production]
      }
    else
      custom_tld_sizes = TLD_SIZES
    end
    SubdomainFu.tld_sizes = custom_tld_sizes
  end

  def self.multischool_settings
    @@multischool_settings = {"domain"=>"lvh.me", "tld_sizes"=>{"development"=>1, "production"=>1, "test"=>0}, "max_school_count"=>1,"organization_details"=>{"name"=>"Fedena","whitelabel"=>false,"school_stats"=>false,"gps_enabled"=>false},"email"=>"info@foradian.com","contact_num"=>"9123123456"}
    settings_from_yml = (YAML.load_file(File.dirname(__FILE__)+"/../config/multischool_settings.yml")["settings"] if File.exists?(File.dirname(__FILE__)+"/../config/multischool_settings.yml")) || {}
    @@multischool_settings = @@multischool_settings.merge!(settings_from_yml)
  end

  module ClassMethods
    def acts_as_multi_school(options = {:read  => true ,:write  => true, :type=>'model'})
      send :include, MultiSchool::ClassInitializer
      send :include, AddSchoolToPaperclip
      send :extend, MultiSchool::Read if options[:read]
      send :include, MultiSchool::Write if options[:write]
      case options[:type]
      when 'model'
        send :include, MultiSchool::DelayedJob::DelayedJobForModel
      when 'class'
        send :include, MultiSchool::DelayedJob::DelayedJobForClass
      end
    end
  end

end
