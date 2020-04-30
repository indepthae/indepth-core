class WeekdaySet < ActiveRecord::Base
  has_many :batches
  has_many :time_table_weekdays
  has_many :weekday_sets_weekdays,:dependent => :destroy

  alias_method :weekdays,:weekday_sets_weekdays

  named_scope :default ,:first

  WEEKDAYS = {
    "0" => "sunday",
    "1" => "monday",
    "2" => "tuesday",
    "3" => "wednesday",
    "4" => "thursday",
    "5" => "friday",
    "6" => "saturday"
  }
  

  def self.common
    WeekdaySet.first(:conditions=>{:is_common=>true})
  end
  
  def self.default_weekdays
    default_weekdays = ActiveSupport::OrderedHash.new
    WEEKDAYS.each do |weekday|
      default_weekdays[weekday.first] = weekday.last
    end
    default_weekdays
  end
  
  def weekday_ids
    weekdays.map(&:weekday_id)
  end

  def weekday_ids=(ids = Array.new)
    if (ids.blank? or ids.nil?)
      weekdays.destroy_all
    else
      weekdays.destroy_all
      ids.map{|id| weekdays.build(:weekday_id => id)}
      save
    end
  end

  def self.weekday_name(weekday_no)
    I18n.translate default_weekdays[weekday_no.to_s].downcase
  end
  def self.shortened_weekday_name(weekday_no)
    I18n.translate default_weekdays[weekday_no.to_s].downcase[0...3]
  end
end
