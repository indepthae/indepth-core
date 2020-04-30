class SubjectSkillSet < ActiveRecord::Base
  validates_presence_of :name
  has_many :subject_skills, :dependent => :destroy
  has_many :subjects
  has_many :course_subjects
  has_many :subject_assessments
  accepts_nested_attributes_for :subject_skills,:allow_destroy => true, :reject_if=> lambda { |a| a[:name].blank? }
  before_save :handle_formula, :if => Proc.new {|ss| !ss.new_record? and ss.calculate_final_changed? }
  after_save :change_sub_skills, :if => Proc.new {|ss| !ss.new_record? and ss.calculate_final_changed? and ss.calculate_final}

  include Gradebook::Rounding

  def round_off (value)
    gb_round_off(value)
  end
  
  def skill_count
    subject_skills.skills.count
  end
  
  def handle_formula
    if calculate_final and formula.blank?
      self.formula = 'sum'
    elsif !calculate_final
      self.formula = nil
    end
  end
  
  def change_sub_skills
    subject_skills.each do |skill|
      skill.calculate_final = true
      skill.save
    end
  end
  
  def formula_text
    formula.present? ? "#{formula.capitalize} of skills scores" : '-'
  end
  
  def dependencies_present?
    subject_skills.present? or course_subjects.present? or subjects.present?
  end
  
  def exam_dependencies_present?
    subject_assessments.present?
  end
  
  def calculate_final_score(marks_hash,scoring_type, subject_maximum, group_maximum)
    if self.calculate_final? and subject_skills.present? and  scoring_type != 2
      extra_keys = marks_hash.keys - subject_skill_ids
      marks = send("calculate_#{self.formula}", marks_hash.except(* extra_keys), subject_maximum)
      {:mark => round_off(marks), :grade => nil, 
                :credit_points => nil, :max_mark => subject_maximum.to_f,
                :converted_mark => round_off((marks.to_f/subject_maximum.to_f)*group_maximum.to_f)}
    end 
  end
  
  def calculate_sum(marks, subject_maximum)
    obtained_marks = marks.map{|id, values| values[:mark].to_f}
    max_marks = marks.map{|id, values| values[:max_mark].to_f}
    ((obtained_marks.sum/max_marks.sum)*subject_maximum.to_f).round(2)
  end
  
  def calculate_average(marks, subject_maximum)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    (converted_marks.sum/marks.length).to_f.round(2)
  end
  
  def calculate_bestof(marks, subject_maximum)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    converted_marks.max
  end
end
