class IaGroup < ActiveRecord::Base
  validates_presence_of :name,:icse_exam_category_id
  belongs_to :icse_exam_category
  has_many :ia_indicators, :dependent => :destroy
  has_and_belongs_to_many :subjects
  has_one :ia_calculation, :dependent => :destroy
  has_many :ia_scores,:through=>:ia_indicators
  accepts_nested_attributes_for :ia_indicators, :allow_destroy=>true
  accepts_nested_attributes_for :ia_calculation, :allow_destroy=>true
  validate :uniqueness_of_indicator
  before_destroy :dependency_check

  def dependency_check
    if ia_scores.present? or subjects.present?
      return false
    end
  end
  private

  def uniqueness_of_indicator
    hash = {}
    ia_indicators.each do |child|
      if hash[child.indicator]
        errors.add(:base, "Indicator is already taken") if errors[:"ia_indicators.indicator"].blank?
      end
      hash[child.indicator] = true
    end
  end
  
end

