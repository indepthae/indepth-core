class VehicleMaintenance < ActiveRecord::Base
  
  belongs_to :vehicle
  has_many :vehicle_maintenance_attachments, :dependent => :destroy
  
  validates_presence_of :name, :vehicle_id, :maintenance_date, :next_maintenance_date, :amount
  
  accepts_nested_attributes_for :vehicle_maintenance_attachments,:allow_destroy=>true, 
    :reject_if=> lambda { |a| a[:name].blank? and a[:attachment].blank? }
  
  #validate dates
  def validate
    if next_maintenance_date.present? && maintenance_date.present?
      errors.add(:next_maintenance_date, :less_than_maintenance_date) if next_maintenance_date < maintenance_date
    end
  end
  
end
