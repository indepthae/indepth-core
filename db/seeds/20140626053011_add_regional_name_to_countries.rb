Country.reset_column_information
Country.all.each do |c|
  name=c.name
  m=name.match(/\(.*\)/)
  unless m.nil?
    c.update_attributes(:name => name.sub(m[0],"").strip,:regional_name => m[0].match(/([^()]+)/)[0])
  end
end
c=Country.find_by_name("Cocos [Keeling] Islands")
c.update_attributes(:name => "Cocos Islands", :regional_name => "Keeling Islands") unless c.nil?
c=Country.find_by_name("Congo [DRC]")
c.update_attribute(:name,"Congo-DRC") unless c.nil?
c=Country.find_by_name("Congo [Republic]")
c.update_attribute(:name,"Congo-Republic") unless c.nil?
c=Country.find_by_name("Falkland Islands [Islas Malvinas]")
c.update_attributes(:name => "Falkland Islands", :regional_name => "Islas Malvinas") unless c.nil?
c=Country.find_by_name("Macedonia [FYROM]")
c.update_attributes(:name => "Macedonia", :regional_name => "Македонија") unless c.nil?
c=Country.find_by_name("Myanmar [Burma]")
c.update_attributes(:name => "Myanmar", :regional_name => "Burma") unless c.nil?