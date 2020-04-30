class SalesUserDetail < ActiveRecord::Base
  belongs_to :invoice 
  belongs_to :user
  validates_presence_of :username
  attr_accessor :issuer_name
  
  HUMANIZED_ATTRIBUTES = {
    :username => "#{t('name')}",
  }
  
  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
   
  def user_details
    if self.user.present?
      self.user.student_entry ||  self.user.archived_student_entry ||  self.user.employee_entry || self.user.archived_employee_entry
    else
      return  nil
    end
  end
  
end
