class IndividualReport < ActiveRecord::Base
  require "#{Rails.root}/lib/gradebook/reports/template.rb"
  Dir["#{Rails.root}/lib/gradebook/components/models/*.rb"].each {|file| require file}
  
  Report = Struct.new(:profile, :main_header, :header, :marks, :excluded_marks, :activities, :overall_marks, :overall_grades, :overall_percentage, :attendance, :records, :remarks) 
  
  serialize :report, Report
  serialize :report_component, Gradebook::Components::Models::Report
  
  belongs_to :reportable, :polymorphic => true
  belongs_to :student
  belongs_to :generated_report_batch
  belongs_to :assessment_group, :foreign_key => :reportable_id
  belongs_to :assessment_plan, :foreign_key => :reportable_id
  belongs_to :assessment_term, :foreign_key => :reportable_id
  has_one :individual_report_pdf, :dependent => :destroy
  
  after_create :generate_pdf_report

  def find_exam_type
    case self.reportable_type 
    when 'AssessmentGroup' 
      exam_type = 'exam_report'
    when 'AssessmentPlan'
      exam_type = 'plan_report'
    when 'AssessmentTerm'
      exam_type = 'term_report'
    end
    return exam_type
  end
  
  def generate_pdf_report
    WickedPdf.config = {:wkhtmltopdf => WickedPdf.config[:wkhtmltopdf]}
    Gradebook::Reports::Builder.build_report(self)
  end
  
  def store_pdf(data)
    file_path = "tmp/"+Time.now.to_i.to_s+rand(1000).to_s
    
    system("mkdir " + file_path)
    File.open(file_path +"/#{student_id}_report.pdf","w") {|file| file.write data}
    individual_pdf = self.individual_report_pdf
    individual_pdf = IndividualReportPdf.find_or_initialize_by_individual_report_id(self.id)
    individual_pdf.update_attributes(:attachment => File.open(file_path + "/#{student_id}_report.pdf",'r'))
    system('rm -rf '+ file_path)
  end

  def report_template
    assessment_plan.report_template
  end
  
  def assessment_plan
    @reportable = reportable
    @assessment_plan ||= if @reportable.is_a? AssessmentPlan
      @reportable
    else
      @reportable.assessment_plan
    end
  end
  
end
