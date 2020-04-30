class CourseExamGroup < ActiveRecord::Base

  GROUP_ATTRIBUTES = %w{name exam_type cce_exam_category_id icse_exam_category_id}

  attr_reader :new_batch_ids
  attr_accessor :maximum_marks, :minimum_marks, :weightage, :send_or_resend_sms, :exam_groups_mode

  belongs_to :course
  has_many :exam_groups do
    def find_target # selective querying for active, inactive and all exam_groups, works based on value of exam_groups_mode
      case proxy_owner.exam_groups_mode
      when :active
        with_scope(:find=>proxy_reflection.klass.active.proxy_options)do
          super
        end
      when :inactive
        with_scope(:find=>proxy_reflection.klass.inactive.proxy_options)do
          super
        end
      else
        super
      end
    end

    def count (*args) # selective count for active, inactive and all exam_groups, works based on value of exam_groups_mode
      case proxy_owner.exam_groups_mode
      when :active
        with_scope(:find=>proxy_reflection.klass.active.proxy_options)do
          super *args
        end
      when :inactive
        with_scope(:find=>proxy_reflection.klass.inactive.proxy_options)do
          super *args
        end
      else
        super *args
      end
    end

  end

  has_many :exams, :through=>:exam_groups, :include=>:subject
  accepts_nested_attributes_for :exam_groups

  validates_presence_of :name,:course_id,:on=>:create
  validates_presence_of :new_batch_ids,:on=>:create,:message=>"#{t('select_atleast_one_batch')}"
  validates_presence_of :icse_exam_category_id, :if =>Proc.new{|course_exam_group| course_exam_group.course.icse_enabled?}
  validates_presence_of :cce_exam_category_id, :if =>Proc.new{|course_exam_group| course_exam_group.course.cce_enabled?}

  before_validation :copy_attributes_to_exam_groups

  def after_initialize
    @exam_groups_mode = :active if exam_groups_mode.nil?
  end

  def batches(reload=false)
    if reload
      @batches_with_scope = Batch.find(batch_ids_with_scope)
    else
      @batches_with_scope ||= Batch.find(batch_ids_with_scope)

    end
  end

  def batch_ids
    batches.collect(&:id)
  end

  def add_batches (batch_ids = [])
    @is_add_batch_txn = true
    @new_batch_ids = batch_ids
    build_exam_groups_for_batches(get_values_hash)
    save
  end

  # for nesting the exams
  def new_exams
    @new_exams ||= get_remaining_subjects.map{|subject|
      exam = Exam.new(:subject_id=>subject.id,:subject_code=>subject.code, :subject_name=>subject.name)
      if @exam_attrs
        if  exam_attr = @exam_attrs.values.find{|attr| attr[:subject_code] == subject.code}
          exam['start_time'] = exam_attr[:start_time]
          exam['end_time'] = exam_attr[:end_time]
          exam['maximum_marks'] = exam_attr[:maximum_marks]
          exam['minimum_marks'] = exam_attr[:minimum_marks]
          exam['_destroy'] = exam_attr[:_destroy]
        end
      end
      exam
    }
  end

  # use this in the form field_for
  def new_exams_attributes= (attrs)
    @exam_attrs = attrs
    @subjects ||= all_available_subjects(batch_ids_with_scope)
    exam_groups.each do |exam_group|
      build_exams_for_batches(attrs, exam_group)
    end
  end

  # works with the new_batch_ids, will build exam attributes for only those batches, also if an exam exist in some other batch it will use the attributes
  def new_batch_exams
    exam_attrs = @exam_attrs.present? ? @exam_attrs.values : exams.all(:select=>"exams.*, subjects.code as subject_code",:joins=>{:subject=>:batch},:conditions=>{:batches=>{:is_active=>true}}, :group=>'subjects.code')\
      .collect{|x| HashWithIndifferentAccess.new x.attributes}
    new_batch_subjects = subjects_for_batches(new_batch_ids)
    @new_batch_exams ||= new_batch_subjects.map{|subject|
      exam = Exam.new(:subject_id=>subject.id,:subject_code=>subject.code, :subject_name=>subject.name)
      if exam_attrs
        exam_attr = exam_attrs.find{|attr| attr[:subject_code] == subject.code} || HashWithIndifferentAccess.new
        exam['start_time'] = exam_attr[:start_time]
        exam['end_time'] = exam_attr[:end_time]
        exam['maximum_marks'] = exam_attr[:maximum_marks]
        exam['minimum_marks'] = exam_attr[:minimum_marks]
        exam['_destroy'] = exam_attr[:_destroy]
      end
      exam
    }
  end

  # nested attributes setter for the new_batch_exams (above)
  def new_batch_exams_attributes= (attrs)
    @exam_attrs = attrs
    @subjects ||= all_available_subjects(new_batch_ids)
    exam_groups.select{|exam_group| new_batch_ids.map{|i| i.to_i }.include? exam_group.batch_id}.each do |exam_group|
      build_exams_for_batches(attrs, exam_group)
    end
  end

  def new_batch_ids= (ids)
    @new_batch_ids = ids.is_a?(Array) ? ids.map{|x| x.to_i} : Array(ids.to_i)
  end

  def batch_ids_with_scope
    exam_groups.collect(&:batch_id)
  end

  private

  def copy_attributes_to_exam_groups
    if @is_add_batch_txn
      @is_add_batch_txn = nil
      return true
    end
    values_hash = get_values_hash
    if new_record?
      build_exam_groups_for_batches(values_hash)
    else
      self.exam_groups_attributes = exam_groups.all.map{|exam_group| values_hash.merge(:id=>exam_group.id)} unless changed.blank?
      if FedenaPlugin.can_access_plugin?('fedena_reminder')
        unless event_alerts.blank?
          exam_groups.each{|exam_group| exam_group.event_alerts = event_alerts}
        end
      end
    end
  end

  def build_exam_groups_for_batches (attr)
    batches = Batch.all(:conditions=>{:id=>@new_batch_ids, :course_id=>course_id})
    batches.each do |batch|
      exam_groups.build(attr.merge(:batch_id=>batch.id))
    end
  end

  def get_values_hash
    Hash[GROUP_ATTRIBUTES.map{|x| [x,attributes[x]]}]
  end

  # get subjects and subjects which is left for exam creation
  def get_remaining_subjects
    subject_codes_for_exclusion = subject_already_with_exams.collect(&:code).uniq
    subjects_for_batches(batch_ids_with_scope).delete_if{|subject| subject_codes_for_exclusion.include? subject.code}
  end

  # select all subjects for the selected batches
  def subjects_for_batches(batch_ids)
    normal_subjects = Subject.find_all_by_batch_id(batch_ids,:group=>"code",:conditions=>{:no_exams => false, :elective_group_id => nil,:is_deleted => false})
    elective_subjects = Subject.find_all_by_batch_id(batch_ids,:group=>"code",:joins=>:students_subjects,:conditions=>["no_exams = false and elective_group_id IS NOT NULL and is_deleted =false"])
    normal_subjects+elective_subjects
  end

  def subject_already_with_exams
    exams.select{|exam| exam_groups.collect(&:id).include? exam.exam_group_id }.map{|x| x.subject}
  end

  def all_available_subjects(batch_ids)
    normal_subjects = Subject.all(:conditions=>{:batch_id=>batch_ids,:no_exams => false, :elective_group_id => nil,:is_deleted => false})
    elective_subjects = Subject.find_all_by_batch_id(batch_ids,:group=>"subjects.id",:joins=>:students_subjects,:conditions=>["no_exams = false and elective_group_id IS NOT NULL and is_deleted =false"])
    subjects=normal_subjects+elective_subjects
    subjects
  end

  def build_exams_for_batches (exams_hash, exam_group)
    exams_hash.each do |_,exam_attributes|
      unless exam_attributes["_destroy"]=="1"
        exam_attributes.delete("_destroy")
        subject = @subjects.find{|subject| subject.batch_id == exam_group.batch_id && subject.code == exam_attributes['subject_code']}
        exam_group.exams.build(exam_attributes.merge(:subject_id => subject.id)) if subject
      end
    end
  end

 
end
