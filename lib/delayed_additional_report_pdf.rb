class DelayedAdditionalReportPdf
  attr_accessor :pdf_report_id
  def initialize(pdf_report_id)
    @pdf_report_id = pdf_report_id
  end

  def perform
    @pdf_report=AdditionalReportPdf.find(@pdf_report_id)
    begin
      @pdf_report.pdf_generation
      @pdf_report.update_attributes(:is_generated => true)
    rescue => exception
      @pdf_report.update_attributes(:is_generated => false, :status => false)
    end
    
    
  end

end