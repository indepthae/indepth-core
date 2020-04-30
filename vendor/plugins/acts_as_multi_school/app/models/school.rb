class School < ActiveRecord::Base

  validates_presence_of :name,:code
  #  validates_uniqueness_of :code, :scope=>:is_deleted, :message=>'is reserved'
  validates_length_of :code,:maximum=>20

  belongs_to :school_group
  belongs_to :creator, :class_name=>"AdminUser"
  has_many :school_domains, :as=>:linkable, :dependent => :destroy
  has_many :gateway_assignees, :as=>:assignee, :dependent=>:destroy
  has_many :assigned_packages, :as=>:assignee, :dependent=>:destroy
  has_one :sms_credential, :as=>:owner
  has_one :smtp_setting, :as=>:owner
  has_one :whitelabel_setting, :as=>:owner
  accepts_nested_attributes_for :school_domains
  has_one :available_plugin, :as=>:associated
  accepts_nested_attributes_for :available_plugin
  
  after_create :create_fedena_school
  before_destroy :remove_sms_settings
  named_scope :active,{:conditions => { :is_deleted => false}}
  def validate
    if school_group.type == "MultiSchoolGroup" && school_group.parent_group.nil?
      limit = max_school_count_setting
      if school_group.schools.active.count >= limit
        self.errors.add_to_base("Maximum number of School Licenses exceeded.")
      end
    end if new_record?
  end

  def maker_id
    creator_id
  end

  def check_allowed_school_limit
    limit = max_school_count_setting
    if School.count(:conditions=>{:is_deleted=>false})>=limit
      errors.add_to_base("You are not allowed to create more than #{limit} schools")
      false
    end
  end

  def create_fedena_school
    MultiSchool.current_school = self
    seed_file = File.join(Rails.root,'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
    FedenaPlugin.load_plugin_seed_data
    self.school_group.load_local_settings(self)
    RecordUpdate.update_school_run(self.id)
    # to add new discount mode marker for new school
    Configuration.set_value('SchoolDiscountMarker', 'NEW_DISCOUNT_MODE')
  end

  def create_fedena_school_seed
    MultiSchool.current_school = self
    seed_file = File.join(Rails.root,'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
    FedenaPlugin.load_plugin_seed_data
    #    self.school_group.load_local_settings(self)
  end

  def multischool_setting_file
    File.join(RAILS_ROOT,"vendor","plugins","acts_as_multi_school","config","multischool_settings.yml")
  end

  def multischool_setting
    MultiSchool.multischool_settings
  end

  def settings_file_exists?
    File.exists?(multischool_setting_file)
  end

  def valid_settings_file?
    settings_file_exists? and multischool_setting["settings"].present?
  end

  def max_school_count_setting
    multischool_setting["max_school_count"].to_i
  end

  def create_sms_settings
    sms_settings = YAML::load(File.open("#{Rails.root}/config/sms_settings.yml.example"))
    ms_sms_settings = YAML::load(File.open("#{Rails.root}/config/sms_settings_multischool.yml")) if File.exists?("#{Rails.root}/config/sms_settings_multischool.yml")
    ms_sms_settings ||= Hash.new
    ms_sms_settings[self.code] = sms_settings
    ms_sms_settings_file = File.new("#{Rails.root}/config/sms_settings_multischool.yml", "w+")
    ms_sms_settings_file.syswrite(ms_sms_settings.to_yaml)
    ms_sms_settings_file.close
  end

  def self.load_sms_settings
    settings = {}
    if File.exists?("#{Rails.root}/config/sms_settings_multischool.yml")
      settings = YAML::load(File.open("#{Rails.root}/config/sms_settings_multischool.yml"))
    end
    return settings
  end

  def self.update_sms_settings(new_settings = Hash.new)
    ms_sms_settings_file = File.new("#{Rails.root}/config/sms_settings_multischool.yml", "w+")
    ms_sms_settings_file.syswrite(new_settings.to_yaml)
    ms_sms_settings_file.close
  end

  def remove_sms_settings
    sms_settings = School.load_sms_settings
    sms_settings.delete(self.code)
    School.update_sms_settings(sms_settings)
  end

  def soft_delete
    if update_attribute(:is_deleted,true)
      school_domains.destroy_all
      delete_sms_packages
    end
  end

  def delete_sms_packages
    assigned_sms_packages = self.assigned_packages
    assigned_sms_packages.each do|a|
      unless a.is_owner
        owner_package = self.school_group.assigned_packages.first(:conditions=>{:sms_package_id=>a.sms_package_id})
        if owner_package.present?
          unused = self.unused_sms(a.sms_package_id)
          owner_package.update_attributes(:sms_used=>(owner_package.sms_used.to_i - unused.to_i))
        end
        a.destroy
      else
        a.sms_package.destroy
      end
    end
  end

  def available_plugins
    (available_plugins_cahce ? existing_cache : []) | FedenaPlugin.non_selectable_plugins
  end
  
  def available_plugins_cahce
    Configuration.cache_it(plugin_cache(self.id, 1)) { available_plugin.present? }
  end
  
  def existing_cache
    Configuration.cache_it(plugin_cache(self.id)) { available_plugin.plugins }
  end
  
  def plugin_cache(school_id, name=nil)
    cache_name = name.present? ? 'available_plugin' : 'available_plugins'
    [cache_name,"/#{school_id}/", 'School']
  end

  def effective_sms_settings
    if inherit_sms_settings
      school_group.effective_sms_settings
    else
      (sms_credential && (sms_credential.settings.is_a? Hash))?  sms_credential.settings : nil
    end
  end

  def effective_smtp_settings
    if inherit_smtp_settings
      school_group.effective_smtp_settings
    else
      (smtp_setting && (smtp_setting.settings.is_a? Hash))? smtp_setting.settings_to_sym : nil
    end
  end

  def self_record
    return self
  end

  def allowed_plugins
    if available_plugins_cahce
      existing_cache
    else
      []
    end
  end

  def unused_sms(sms_package_id)
    unused_sms = 0
    assigned_package = self.assigned_packages.first(:conditions=>{:sms_package_id=>sms_package_id})
    if assigned_package.present?
      unused_sms = assigned_package.sms_count.to_i - assigned_package.sms_used.to_i
    end
    return unused_sms
  end

  def delete_associated_packages(sms_package_id)
    return true
  end

  private
  #  def cache_flush
  #    users.each do |user|
  #      Rails.cache.delete("user_main_menu#{user.id}")
  #    end
  #  end

end

