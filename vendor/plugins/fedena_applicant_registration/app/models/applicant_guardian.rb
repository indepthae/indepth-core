class ApplicantGuardian < ActiveRecord::Base
  belongs_to :applicant
  belongs_to :country
  
  attr_accessor :relation_type
  #validates_presence_of :first_name,:relation
  validates_format_of  :email, :with => /^[\+A-Z0-9\._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,6}$/i,:if=>:check_email, :message => :address_must_be_valid

  HUMANIZED_COLUMNS = {:first_name => "#{t('guardian_first_name')}",:relation=>"#{t('guardian_relation')}",:email=>"#{t('guardian_email')}",:dob=>"#{t('guardian_dob')}"}
  
  def validate
    mandatory_attributes = self.applicant.m_g_attr
    if mandatory_attributes.present?
      mandatory_attributes.split(", ").each do|m|
        self.applicant.errors.add_to_base("#{ApplicantGuardian.human_attribute_name(m)} can't be blank") unless self.send(m).present?
      end
    end
    unique_gruadian = self.applicant.guardians
    if  unique_gruadian.present?  and unique_gruadian.count > 1
      f_gruadian = []
      s_gruadian = []
      th_gruadian = []
      f_gruadian <<   [unique_gruadian["0"]["relation"], unique_gruadian["0"]["first_name"].squish  , unique_gruadian["0"]["last_name"].try(:squish)]
      s_gruadian <<   [unique_gruadian["1"]["relation"], unique_gruadian["1"]["first_name"].squish , unique_gruadian["1"]["last_name"].try(:squish)]
      th_gruadian <<  [unique_gruadian["2"]["relation"], unique_gruadian["2"]["first_name"].squish  , unique_gruadian["2"]["last_name"].try(:squish)] if unique_gruadian.count > 2
   
      
      if f_gruadian == s_gruadian
        self.applicant.errors.add_to_base("Guardians can't be same") 
      elsif  unique_gruadian.count > 2 and s_gruadian == th_gruadian
        self.applicant.errors.add_to_base("Guardians can't be same") 
      elsif  unique_gruadian.count > 2 and f_gruadian == th_gruadian
        self.applicant.errors.add_to_base("Guardians can't be same") 
      end
    end
  end

  
  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end
  
  def check_email
    !email.blank?
  end
  
  def translated_relation
    (self.relation == 'father' or self.relation == 'mother') ? I18n.t("#{self.relation}") : self.relation
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end

end
