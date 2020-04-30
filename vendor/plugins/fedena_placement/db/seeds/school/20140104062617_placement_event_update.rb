placement_events = Event.find(:all , :conditions => {:origin_id => nil, :origin_type => nil, :title => ["توظيف","實習","Colocación","नियुक्ति", "جێگا", "Байршуулалт","Vagas/Anúncios","Giới thiệu việc làm","Placement"]})
if placement_events.count > 0
  Event.destroy_all(:origin_id => nil, :origin_type => nil, :title => "Placement")
  Placementevent.all.each do |event|
    Event.create(:title=> "Placement", :description=> "Company: #{event.company} <br/>Details: #{event.description}", :start_date=> event.date, :end_date=> event.date, :origin => event)
  end
end