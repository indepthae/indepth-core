class Warden < ActiveRecord::Base
  belongs_to :employee
  belongs_to :hostel
  validates_presence_of :hostel_id, :employee_id
  validates_uniqueness_of :employee_id, :scope => :hostel_id

  HUMANIZED_COLUMNS = {:employee_id => "#{t('wardens.warden')}"}

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def employee_details
    e=self.employee
    if e.present?
      return e
    else
      return ArchivedEmployee.find_by_former_id(self.employee_id)
    end
  end
end
