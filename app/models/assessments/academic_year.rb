class AcademicYear < ActiveRecord::Base
  
  has_many :batches
  has_many :assessment_plans
  has_many :assessment_groups
  has_many :marked_attendance_records
  
  validates_presence_of :name, :start_date, :end_date
  validates_uniqueness_of :name,:case_sensitive => false
  validates_length_of :name , :maximum => 25
  
  named_scope :active, :conditions => {:is_active => true}
  named_scope :inactive, :conditions => {:is_active => false}
  
  def validate
    if dependencies_present?
      errors.add(:start_date, :start_date_cant_be_modified) if start_date_changed?
      errors.add(:end_date, :end_date_cant_be_modified) if end_date_changed?
    end
    if start_date > end_date
      errors.add(:start_date, :start_date_cant_be_after_end_date) 
    else
      overlap = if new_record?
        AcademicYear.all(:conditions =>["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date))",
            start_date, end_date, start_date, end_date, start_date, end_date])
      else
        AcademicYear.all(:conditions =>["((start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)) AND id != ?",
            start_date, end_date, start_date, end_date, start_date, end_date, id])
      end
      errors.add(:start_date, :overlap_existing_academic_year) if overlap.present?
    end
  end
  
  def range
    "#{format_date(start_date)} - #{format_date(end_date)}"
  end
  
  def make_active
    self.class.update_all('is_active = false', ["school_id = ?", MultiSchool.current_school.id])
    self.reload
    self.update_attribute(:is_active, true)
  end
  
  def duration
    TimeDuration.formatted_string(start_date, end_date, '%y, %M, %w, %d')
  end
  
  def dependencies_present?
    batches.all( :conditions => {:is_deleted=>false} ).present? or assessment_plans.present? or assessment_groups.present?
  end
  
  #  def duration
  #    duration_in_months = (end_date.year * 12 + end_date.month ) - (start_date.year * 12 + start_date.month)
  #    month = end_date.strftime("%m") == start_date.strftime("%m") ? 0 : (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  #    years = duration_in_months / 12
  #    days = end_date.strftime("%m%Y") == start_date.strftime("%m%Y") ? (end_date-start_date).to_i : (start_date.day == end_date.day ? 0 : (start_date.day.to_i - 1))
  #    "#{years} year, #{month} months and #{days} days"
  #  end
  
  
  def self.fetch_academic_year_id
    AcademicYear.active.first.try(:id)
  end
 
  
end
