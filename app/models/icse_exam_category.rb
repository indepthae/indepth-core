class IcseExamCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :exam_groups
  has_many :icse_weightages
  has_many :ia_groups
  before_destroy :dependency_check

  def dependency_check
    if exam_groups.present? or icse_weightages.present? or ia_groups.present?
      return false
    end
  end
end
