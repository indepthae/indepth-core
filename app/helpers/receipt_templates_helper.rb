module ReceiptTemplatesHelper
  
  def get_header_template header_template
    if @receipt_printer.present?
      current_template = ReceiptPrinter::RECEIPT_PRINTER_TEMPLATES[@receipt_printer.receipt_printer_template]
    else
      current_template = ReceiptPrinter::get_receipt_printer_template
    end

    case current_template.parameterize.underscore.to_s
    when "a5_portrait"
      header_template.send("header_content_a5_portrait")
    when "thermal_responsive"
      header_template.send("header_content_thermal_responsive")
    else # default case A4 or A5 Landscape (same as A4, in width) 
      header_template.send("header_content")
    end
  end
  
end
