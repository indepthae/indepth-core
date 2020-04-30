class CertificateType < ActiveRecord::Base
  
  has_many :vehicle_certificates
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  before_destroy :check_dependencies
  
  named_scope :active, :conditions => {:is_active => true}
  named_scope :inactive, :conditions => {:is_active => false}
  named_scope :include_certificates , :include => :vehicle_certificates
  
  #returns send reminders status
  def send_reminders_text
    send_reminders ? t('yes_text') : t('no_texts')
  end
  
  #returns status translated text
  def status
    is_active ? t('active') : t('inactive')
  end
  
  #checks any certificate is present for this certificate type before destroying
  def check_dependencies
    !VehicleCertificate.exists?(:certificate_type_id => id)
  end 
end
