class PinNumber < ActiveRecord::Base
  belongs_to :pin_group
  validates_presence_of :pin_group_id,:number
  validates_numericality_of :number,:length => 14
  validates_uniqueness_of :number
  
  named_scope :active,{ :conditions => { :is_active => true }}
  named_scope :inactive,{ :conditions => { :is_active => false }}
  named_scope :registered,{ :conditions => { :is_registered => true }}
  
  def self.pin_status(pin, course_id)
    pin_no = PinNumber.find_by_number(pin)
    if pin_no.present?
      if Date.today > pin_no.pin_group.valid_till.to_date or Date.today < pin_no.pin_group.valid_from.to_date or !pin_no.is_active? or pin_no.is_registered? or !pin_no.pin_group.course_ids.include?(course_id.to_s)
        false
      else
        true
      end
    else
      false
    end
  end
  
end
