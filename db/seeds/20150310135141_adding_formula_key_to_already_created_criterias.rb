if (MultiSchool rescue false)
  School.active.each do |school|
    MultiSchool.current_school=school
    FaGroup.active.each do |group|
      group.update_attribute('di_formula',1)
      key="A"
      group.fa_criterias.active.each do |criteria|
        criteria.update_attributes(:formula_key=>key,:max_marks=>group.max_marks)
        key.next!
      end
    end
    so=1
    ObservationGroup.active.each do |ob|
      ob.update_attribute('sort_order',so)
      so=so.next
    end
  end
else
  FaGroup.active.each do |group|
    group.update_attribute('di_formula',1)
    key="A"
    group.fa_criterias.active.each do |criteria|
      criteria.update_attributes(:formula_key=>key,:max_marks=>group.max_marks)
      key.next!
    end
  end
  so=1
  ObservationGroup.active.each do |ob|
    ob.update_attribute('sort_order',so)
    so=so.next
  end
end