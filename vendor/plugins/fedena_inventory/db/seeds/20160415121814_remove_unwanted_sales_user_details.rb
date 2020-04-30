if (MultiSchool rescue false)
  School.active.each do |s|
    MultiSchool.current_school = s
    inv_ids=Invoice.all.collect(&:id)
    SalesUserDetail.all(:conditions=>["invoice_id NOT IN (?)",inv_ids]).each do |e|
      e.destroy
    end
  end
end