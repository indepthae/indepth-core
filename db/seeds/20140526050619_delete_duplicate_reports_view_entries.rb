Privilege.find(:all,:conditions=>["name=? and privilege_tag_id IS NULL",'ReportsView']).each do |entry|
  entry.destroy
end