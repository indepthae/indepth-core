if (MultiSchool rescue false)
  School.active.each do |s|
    MultiSchool.current_school = s
    invoices=Invoice.paid
    grns = Grn.paid
    invoices.each do |invoice|
      invoice.update_attributes(:tax_mode =>0)
    end
    grns.each do | grn |
      grn.update_attributes(:tax_mode=>0)
    end
  end
end
