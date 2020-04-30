class AssessmentSchedule < ActiveRecord::Base
  attr_accessor :first_start_time, :first_end_time, :second_start_time, :second_end_time, :third_start_time, :third_end_time
  serialize :exam_timings
  serialize :mark_entry_last_date, Hash
  
  belongs_to :assessment_group
  belongs_to :course
  has_and_belongs_to_many :batches
  
  validates_presence_of :start_date, :end_date, :first_start_time, :first_end_time
  validates_format_of :first_start_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "first_start_time.present?"
  validates_format_of :first_end_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "first_end_time.present?"
  validates_presence_of :second_start_time, :second_end_time, :if => "no_of_exams_per_day > 1"
  validates_format_of :second_start_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "no_of_exams_per_day > 1 and second_start_time.present?"
  validates_format_of :second_end_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "no_of_exams_per_day > 1 and second_end_time.present?"
  validates_presence_of :third_start_time, :third_end_time, :if => "no_of_exams_per_day > 2"
  validates_format_of :third_start_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "no_of_exams_per_day > 2 and third_start_time.present?"
  validates_format_of :third_end_time, :with => /^(0?[1-9]|1[012])(:[0-5]\d) [APap][mM]$/, :if => "no_of_exams_per_day > 2 and third_end_time.present?"
  
  validate :check_dates
  validate :check_timings
  
  before_save :arrange_timings
  
  TIMINGS_IN_WORDS = {1 => "first", 2 => "second", 3 => "third"}
  
  def check_dates
    errors.add(:start_date, :start_date_cant_be_after_end_date) if start_date > end_date
  end
  
  def check_timings
    errors.add(:first_end_time, :can_not_be_before_the_start_time) if Time.parse(first_start_time) > Time.parse(first_end_time)
    errors.add(:second_end_time, :can_not_be_before_the_start_time) if no_of_exams_per_day > 1 and Time.parse(second_start_time) > Time.parse(second_end_time)
    errors.add(:third_end_time, :can_not_be_before_the_start_time) if no_of_exams_per_day > 2 and Time.parse(third_start_time) > Time.parse(third_end_time)
  end
  
  def arrange_timings
    if first_start_time.present? and first_end_time.present?
      timings = {1 => {:start_time => first_start_time, :end_time => first_end_time}}
      timings[2] = {:start_time => second_start_time, :end_time => second_end_time} if no_of_exams_per_day > 1
      timings[3] = {:start_time => third_start_time, :end_time => third_end_time} if no_of_exams_per_day > 2
      self.exam_timings = timings
    end
  end
  
  def set_timings
    self.first_start_time = exam_timings[1][:start_time]
    self.first_end_time = exam_timings[1][:end_time]
    if no_of_exams_per_day > 1
      self.second_start_time = exam_timings[2][:start_time]
      self.second_end_time = exam_timings[2][:end_time]
    end
    if no_of_exams_per_day > 2
      self.third_start_time = exam_timings[3][:start_time]
      self.third_end_time = exam_timings[3][:end_time]
    end
  end
  
  class << self
    
    def fetch_batches(group, course, id = nil)
      condition = "AND id <> #{id}" if id.present?
      destroy_all(["course_id = ? AND assessment_group_id = ? AND schedule_created = false #{condition}", course.id, group.id])
#      destroy_all(["course_id = ? AND assessment_group_id = ? #{condition}", course.id, group.id]) if id.nil?
      #
      #FixMe: Check above destroy case. try to change to all schedules
      #
#      schedules = all(:conditions => ["course_id = ? AND assessment_group_id = ? #{condition}", course.id, group.id], :include => :batches)
#      batches_list = schedules.collect(&:batches).flatten
#      batches = (group.is_course_exam? ? group.batches : course.batches_in_academic_year(group.academic_year_id))
      
      all_batches = course.batches_in_academic_year(group.academic_year_id).select{|b| b.is_active }
      batches_with_assessments = group.assessment_group_batches.all(:conditions => ['batch_id in (?)', all_batches.collect(&:id).uniq],
        :joins => :subject_assessments, :select => 'distinct assessment_group_batches.*').collect(&:batch_id)
      return all_batches.reject{|b| batches_with_assessments.include? b.id }.uniq
      
#      (batches - batches_list)
    end
    
  end
  
end
