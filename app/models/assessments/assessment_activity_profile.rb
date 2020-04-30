class AssessmentActivityProfile < ActiveRecord::Base
  
  has_many :assessment_activities
  has_many :assessment_groups
  has_many :activity_assessments
  
  accepts_nested_attributes_for :assessment_activities,:allow_destroy => true, :reject_if=> lambda { |a| a[:name].blank? and a[:description].blank? }
  
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :description, :maximum => 250
  
  validate :check_attributes
  before_save :check_dependents
  
  def validate
    errors.add(:base, :dependencies_exist) if dependencies_present?
  end
  
  def activities_count
    assessment_activities.length
  end
  
  def dependencies_present?
    assessment_groups.present?
  end
  
  def check_dependents
    assessment_activities.each do |activity|
      activity.mark_for_destruction if activity.name.blank? and activity.description.blank?
    end
  end
  
  def check_attributes
    activities = assessment_activities.select{|a| !a.marked_for_destruction?}.group_by{|gr| gr.name.downcase}
    activities.each do |name, activity|
      if name.present? and activity.length > 1
        activity.each{|gr| gr.errors.add(:name, :taken)}
        errors.add(:base, :dependencies_exist)
      end
    end
  end
  
end
