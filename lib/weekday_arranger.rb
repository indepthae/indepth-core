# To change this template, choose Tools | Templates
# and open the template in the editor.

module WeekdayArranger
  class Weekdays < ActiveRecord::Base
    WEEKDAYS = {
      "0" => "sunday",
      "1" => "monday",
      "2" => "tuesday",
      "3" => "wednesday",
      "4" => "thursday",
      "5" => "friday",
      "6" => "saturday"
    }
    SHORT_WEEKDAYS = {
      "0" => "sun",
      "1" => "mon",
      "2" => "tue",
      "3" => "wed",
      "4" => "thu",
      "5" => "fri",
      "6" => "sat"
    }
  end
  
  def weekday_names
    start_day=Configuration.find_by_config_key('StartDayOfWeek').config_value
    days_of_week=Weekdays::WEEKDAYS.sort {|a,b| a[0]<=>b[0]}
    new_days_of_week=[]
    for i in (start_day.to_i..6)
      new_days_of_week<< I18n.t(days_of_week[i][1])
    end
    for i in (0..start_day.to_i-1)
      new_days_of_week<<I18n.t(days_of_week[i][1])
    end
    new_days_of_week
  end

  def weekday_numbers
    start_day=Configuration.find_by_config_key('StartDayOfWeek').config_value
    days_of_week=Weekdays::WEEKDAYS.sort {|a,b| a[0]<=>b[0]}
    new_days=[]
    for i in (start_day.to_i..6)
      new_days<<days_of_week[i][0].to_i
    end
    for i in (0..start_day.to_i-1)
      new_days<<days_of_week[i][0].to_i
    end
    new_days
  end

  def weekday_arrangers(weekdays=[])
    start_day=Configuration.find_by_config_key('StartDayOfWeek').config_value
    new_days=[]
    for i in (start_day.to_i..6)
      new_days<<i if weekdays.include?(i)
    end
    for i in (0..start_day.to_i-1)
      new_days<<i if weekdays.include?(i)
    end
    new_days
  end

  def weekday_hash
    start_day=Configuration.find_by_config_key('StartDayOfWeek').config_value
    days_of_week=Weekdays::SHORT_WEEKDAYS.sort {|a,b| a[0]<=>b[0]}
    new_days=[]
    for i in (start_day.to_i..6)
      new_days<<[days_of_week[i][0].to_i,I18n.t(days_of_week[i][1])]
    end
    for i in (0..start_day.to_i-1)
      new_days<<[days_of_week[i][0].to_i,I18n.t(days_of_week[i][1])]
    end
    new_days
  end

  def hash_weekdays
    start_day=Configuration.find_by_config_key('StartDayOfWeek').config_value
    week_days=Weekdays::WEEKDAYS
    default_weekdays = ActiveSupport::OrderedHash.new
    for i in (start_day.to_i..6)
      default_weekdays[i]=week_days[i.to_s]
    end
    for i in (0..start_day.to_i)
      default_weekdays[i]=week_days[i.to_s]
    end
    default_weekdays
  end
end
