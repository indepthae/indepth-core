class AssessmentFormField < Tableless

  column :date, :date
  column :start_time, :time
  column :end_time, :time
  column :max_marks, :decimal
  column :min_marks, :decimal
  column :assessment_form_id, :integer
  
  validates_presence_of :date, :start_time, :end_time
  
  belongs_to :assessment_form
  has_many :subject_assessments
  
  accepts_nested_attributes_for :subject_assessments, :allow_destroy => true#, :reject_if => lambda { |l| l[:selected] == "0" }
end
