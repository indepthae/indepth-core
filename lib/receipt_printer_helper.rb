module ReceiptPrinterHelper
  include ApplicationHelper
  
  def get_stylesheet_for_current_receipt_template
    stylesheets=[]
    stylesheets<<"_receipt_templates/receipt_global"
    if rtl?
      stylesheets<<receipt_path+'/rtl/_template_'+template_name
    else
      stylesheets<<receipt_path+'/_template_'+template_name
    end
    stylesheets=[stylesheets,{:media=>"all"}]
  end
  
  def get_stylesheet_for_receipt_template(template_name)
    template_name=template_name.parameterize.underscore.to_s
    stylesheets=[]
    stylesheets<<"_receipt_templates/receipt_global"
    if rtl?
      stylesheets<<receipt_path+'/rtl/_template_'+template_name
    else
      stylesheets<<receipt_path+'/_template_'+template_name
    end
    stylesheets=[stylesheets,{:media=>"all"}]
  end
  
  def get_current_receipt_partial
    #    "_receipt_templates/template_"+template_name+".html.erb"
    get_receipt_partial(current_template)
  end
  
  def get_partial_for_current_receipt_template
    receipt_path + template_name
  end
  
  def receipt_path
    "_receipt_templates"
  end
  
  def current_template
    ReceiptPrinter::get_receipt_printer_template
  end
  
  def template_name
    ReceiptPrinter::get_receipt_printer_template.parameterize.underscore.to_s
  end
  
  def get_receipt_partial(template)
    #    template = "A4" if template == "A5 Landscape"
    folder = template.split(" ")[0].underscore
    template_name = "template_#{template.parameterize.underscore}"
    return "finance_extensions/receipts/print/#{folder}/#{template_name}"    
  end
  
  def precision_label_with_currency(amount)
    currency + " " + precision_label(amount)
  end
  # receipt template helpers
  def has_fine?(v)
    v.total_fine_amount.present? && v.total_fine_amount.to_f > 0.0
  end
  
  def has_discount?(v)
    v.total_discount.present? && v.total_discount.to_f > 0.0
  end
  
  def has_tax?(v)
#    v.tax_enabled && v.tax_slab_collections.present?
    v.tax_enabled && v.total_tax.to_f > 0.0
  end
  
  def has_previously_paid_fees?(v)
    v.previously_paid_amount.present? && v.previously_paid_amount.to_f > 0.0
  end
  
  def has_due?(v)
    v.total_due_amount.to_f > 0.0
  end
  
  def has_due_date?(v)
    v.total_due_amount.present?
  end
  
  def has_roll_number?(v)
    v.payee.roll_number && roll_number_enabled?
  end
  
  def particular_has_discount(particular)
    particular.discount.to_f > 0.0
  end
  
  def particular_has_previous_payments(particular)
    particular.amount != particular.remaining_balance
  end
  #settings page
  def current_receipt_template_preview_url
    @current_receipt_printer_type=ReceiptPrinter.receipt_printer_template
    "#{Fedena.hostname}/finance/fees_receipt_preview?type=#{ReceiptPrinter.receipt_printer_template}"
  end

  def reference_no_label(v)
    case v["payment_mode"]
    when "Online Payment"
      t('transaction_id')
    when "Cheque"
      t('cheque_no')
    when "DD"
      t('dd_no')
    else
      t('reference_no')
    end
  end
  
  def has_particulars?(v)
    (v.categorized_particulars.present? and v.is_particular_wise == false) || (v.particulars_list.present?  && v.is_particular_wise == true )
  end
  
  def clean_output(amount)
    amount.zero? && 0.0 || amount
  end
end
