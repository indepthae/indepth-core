class IaScore < ActiveRecord::Base
  belongs_to :student
  belongs_to :exam
  belongs_to :batch
  belongs_to :ia_indicator
  validates_numericality_of :mark,:allow_blank=>true
  before_save :mark_validation

  def mark_validation
    if self.mark.to_f > self.ia_indicator.max_mark.to_f
      errors.add(:ia_score,"Mark cannot be greater than maximum mark")
      return false
    end
  end

end
