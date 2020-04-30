class ClassTimingSet < ActiveRecord::Base
  validates_presence_of :name
  before_destroy :check_dependency
  has_many :batch_class_timing_sets
  has_many :class_timings, :dependent => :destroy
  has_many :time_table_class_timings, :dependent => :destroy
  has_many :time_table_class_timing_sets, :dependent => :destroy
  has_many :batches

  def check_dependency
    error=false
    bcts = batch_class_timing_sets.all(:joins=>{:batch=>:course},:select=>"batch_class_timing_sets.*,CONCAT(courses.code,'-',batches.name) batch_full_name")
    if bcts.present?
      errors.add_to_base "#{t('batch_dependencies_exist')}" + " #{bcts.collect(&:batch_full_name).uniq.sort.join(", ") }"
      error=true
    end
    if TimeTableClassTimingSet.find_by_class_timing_set_id(self.id).present?
      errors.add_to_base :timetable_dependencies_exist
      error=true
    end
    if error
      return false
    end
  end
end
