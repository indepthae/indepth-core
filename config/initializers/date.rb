class Date
  def self.today_with_timezone
    FedenaTimeSet.current_time_to_local_time(Time.now).to_date
  end
end
