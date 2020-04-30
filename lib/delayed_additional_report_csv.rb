class DelayedAdditionalReportCsv
  attr_accessor :csv_report_id
  def initialize(csv_report_id)
    @csv_report_id = csv_report_id
  end

  def perform
    @csv_report=AdditionalReportCsv.find(@csv_report_id)
    begin
      @csv_report.csv_generation
      @csv_report.update_attributes(:is_generated => true)
    rescue => exception
      @csv_report.update_attributes(:is_generated => false, :status => false)
    end
  end

end