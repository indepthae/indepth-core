class SmsPackage < ActiveRecord::Base

  serialize :settings

  validates_presence_of :name,:service_provider,:settings
  validates_numericality_of :message_limit, :only_integer=>true, :greater_than=>0, :allow_nil=>true
  validates_numericality_of :character_limit, :only_integer=>true, :greater_than=>0, :allow_nil=>true
  validates_numericality_of :multipart_character_limit, :only_integer=>true, :greater_than=>0, :allow_nil=>true

  has_many :assigned_packages, :dependent=>:destroy

  before_save :build_proper_url
  after_update :modify_school_settings

  def validate
    if self.validity.present?
      df = self.validity.to_date rescue false
      unless df==false
        self.errors.add(:validity,"cannot be a past date.") if self.validity.to_date < Date.today
        self.errors.add(:validity,"cannot be greater than 100 years.") if self.validity.to_date > (Date.today + 100.years)
        greater_validity = self.assigned_packages.first(:conditions=>["validity > ? and is_owner is false",self.validity],:order=>"validity desc")
        self.errors.add_to_base("Package with validity #{greater_validity.validity} already assigned. Validity cannot be less than that.") if greater_validity.present?
        if self.validity_was.nil?
          self.errors.add_to_base("Package with lifetime validity already assigned.") if self.assigned_packages.first(:conditions=>["validity IS NULL and is_owner is false"]).present?
        end
      else
        self.errors.add(:validity,"Invalid date.")
      end
    end
    if self.message_limit.present?
      assigned_row = self.assigned_packages.first(:conditions=>{:is_owner=>true})
      if assigned_row.present?
        self.errors.add_to_base("#{assigned_row.sms_used.to_i} SMS have already been used. Message Limit cannot be less than that.") if self.message_limit.to_i < assigned_row.sms_used.to_i
      end
      if self.message_limit_was.nil?
        self.errors.add_to_base("Package with unlimited SMS count already assigned.") if self.assigned_packages.first(:conditions=>["sms_count IS NULL and is_owner is false"]).present?
      end
    end
  end

  def build_proper_url
    self.settings["sms_settings"]["host_url"] = self.settings["sms_settings"]["host_url"].delete(" ")
  end

  def modify_school_settings
    if self.settings_changed?
      schools_using = self.assigned_packages.all(:conditions=>{:assignee_type=>"School",:is_using=>true},:include=>:assignee)
      if schools_using.present?
        schools_using.each do|a|
          sender_name = a.sendername
          updated_settings = self.settings
          updated_settings[:sms_settings][:sendername] = sender_name
          a.assignee.sms_credential.update_attributes(:settings=>updated_settings)
        end
      end
    end
  end

end
