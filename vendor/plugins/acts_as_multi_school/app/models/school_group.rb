class SchoolGroup < ActiveRecord::Base
  has_many :schools
  has_many :school_domains, :as=>:linkable, :dependent => :destroy
  has_many :gateway_assignees, :as=>:assignee, :dependent=>:destroy
  has_many :assigned_packages, :as=>:assignee
  has_one :available_plugin, :as=>:associated
  has_one :attachment, :as=>:owner
  has_one :sms_credential, :as=>:owner
  has_one :smtp_setting, :as=>:owner
  has_one :whitelabel_setting, :as=>:owner
  has_many :active_schools, :class_name=>"School", :conditions =>{:is_deleted=>false}
  has_one :local_setting, :as=>:owner

  
  accepts_nested_attributes_for :school_domains
  accepts_nested_attributes_for :available_plugin

  validates_presence_of :name
  
  belongs_to :admin_user
  belongs_to :parent_group

  @@humanized_attributes = {"name"=>"Organization"}

  def self.human_attribute_name (attr)
    @@humanized_attributes[attr] || super
  end
  
  def validate
    if self.license_count
      self.errors.add(:license_count, "must be greater than 0") if self.license_count < 1
    end
  end  

  def maker_id
    admin_user_id
  end
 
  def self.all_plugins
    @@all_plugins ||= FedenaPlugin.selectable_plugins
  end

  def allowed_plugins
    if parent_group_id.nil? and admin_user_id.nil?
      self.class.all_plugins
    else
      if available_plugin
        available_plugin.plugins
      else
        []
      end
    end
  end

  def effective_sms_settings
    if sms_credential && (sms_credential.settings.is_a? Hash)
      sms_credential.settings
    else
      FedenaSetting.sms_settings_from_yml
    end
  end

  def effective_smtp_settings
    if smtp_setting && (smtp_setting.settings.is_a? Hash)
      smtp_setting.settings_to_sym
    else
      FedenaSetting.smtp_settings
    end
  end

  def effective_white_label
    if whitelabel_setting && whitelabel_enabled?
      whitelabel_setting.settings_to_sym
    elsif parent_group && parent_group.whitelabel_setting
      parent_group.whitelabel_setting.settings_to_sym
    else
      nil
    end
  end

  def self_record
    return self
  end
  
end


  
