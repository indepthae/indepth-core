class GenerateReportPdf
  
  def self.export_pdf(model, method, parameters, opts)

    pdf_report=AdditionalReportPdf.find_by_model_name_and_method_name(model,method)
    if pdf_report.nil?
      pdf_report=AdditionalReportPdf.new(:model_name=>model,:method_name=>method,:parameters=>parameters, :status => true, :opts => opts)
      if pdf_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportPdf.new(pdf_report.id),{:queue => "additional_reports"})
      end
    else
      unless pdf_report.status
        if pdf_report.update_attributes(:parameters=>parameters, :opts => opts, :status => true, :pdf_report=>nil)
          Delayed::Job.enqueue(DelayedAdditionalReportPdf.new(pdf_report.id),{:queue => "additional_reports"})
        end
      end  
    end
  end
  
end