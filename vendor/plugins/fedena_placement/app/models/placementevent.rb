class Placementevent < ActiveRecord::Base
  has_many :placement_registrations ,:dependent=>:destroy
  has_many :students ,:through=>:placement_registrations

  validates_presence_of :title,:date,:company

  named_scope :active,{:conditions=>{:is_active=>true}}
  named_scope :inactive,{:conditions=>{:is_active=>false}}
  named_scope :active_placements,{:conditions=>{:is_active=>true},:order =>'date desc'}
  named_scope :inactive_placements,{:conditions=>{:is_active=>false},:order =>'date desc'}

  def validate
    if self.date.to_date < Date.today
      errors.add_to_base :date_cant_be_past_date
      return false
    else
      return true
    end
  end
#  def check_invitation?
#    self.placement_registrations.collect(&:student_id).include?(Authorization.current_user.student_record.id)
#  end
  def user_ids
    students.collect(&:user_id)
  end
end
