# To change this template, choose Tools | Templates
# and open the template in the editor.

class DateFormat
  cattr_accessor :order,:separator
  @@order = ['DMY', 'MDY', 'YMD']
  @@separator = ['/', '-']
  def initialize    
    #    @formats = [:long,:month,:month_year,:short,:time,:year]
    #    @format = Configuration.get_config_value('DateFormat') || 1
    #    @order = ['dmy','mdy', 'ymd']

    @format = @format || Configuration.get_config_value('DateFormat') || 1
    @format_separator = @format_separator || Configuration.get_config_value('DateFormatSeparator') || '/'
  end

  def get_format
    #    Configuration.get_config_value('DateFormat') || 1
    @format
  end

  def format date, str=:short
    return '' unless date.present? ## if date is nil or not present
    begin
      date = date.to_date if (date.class == String && date.length <= 10)
      date = date.to_datetime if date.class != Date
    rescue
      return ''
    end
    if str == :short_date or str == :long_date
      date = date.to_date if date.class != Date ## converts a non date to date object
      str = str == :long_date ? :long : :short
    end
    if str == :short or str == :long
      set_format(date.class,str) if str == :short
      str = "#{str.to_s}_#{@format}".to_sym
    end
    date.to_formatted_s(str)    
  end

  def set_format klass,str
    case @format.to_i
    when 2
      formatter = ['m','d','Y']
    when 3
      formatter = ['Y','m','d']
    else
      formatter = ['d','m','Y']
    end
    klass = (klass == DateTime || klass == Time) ? Time : klass
    klass::DATE_FORMATS["short_#{@format}".to_sym] = proc { |time| time.strftime("%#{formatter[0]}#{@format_separator}%#{formatter[1]}#{@format_separator}%#{formatter[2]} #{klass == Time ? '%I:%M %p' : ''}")}
  end
end
