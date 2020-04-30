module DateFormater
  mattr_accessor :date_format_obj

  def self.extended(klass)
    ActionController::Base.instance_eval do
      before_filter Proc.new{ klass.clean_date_format }
    end
  end

  def format_date(date,*params)
    DateFormater.date_format_obj ||= DateFormat.new
    opts=params.extract_options!

    # date format is picked from configuration
    # full or short date format is as per format
    # default date format is short format
    format = opts[:format] || :short

    DateFormater.date_format_obj.format(date,format)
  end

  def date_format
    DateFormater.date_format_obj ||= DateFormat.new
    DateFormater.date_format_obj.get_format
  end

  def clean_date_format
    DateFormater.date_format_obj = nil
  end

end
::ActiveRecord::Base.send :include, DateFormater
::ActiveRecord::Base.send :extend, DateFormater