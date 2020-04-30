class IcseWeightage < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :icse_exam_category_id
  validates_presence_of :ea_weightage,:ia_weightage,:grade_type
  validates_numericality_of :ia_weightage,:ea_weightage,:allow_blank=>true
  belongs_to :icse_exam_category
  has_and_belongs_to_many :subjects
  before_save :validate_weightage
  before_destroy :dependency_check

  def validate_weightage
    if self.ea_weightage + self.ia_weightage != 100
      errors.add(:base,"Total Weightage must be equal to 100")
      return false
    end
  end

  def dependency_check
    if subjects.present?
      return false
    end
  end
end
