class FedenaPrecision

  class << self
    def set_and_modify_precision value, precision_count = nil
      if defined? value and value != '' and !value.nil?
        @precision_count ||= precision_count
        @precision_count ||= Configuration.get_config_value('PrecisionCount')
        @precision_count = calculate_precision @precision_count
        value = sprintf("%0.#{@precision_count}f",value)
      else
        return
      end
    end

    def get_precision_count
      @precision_count = @precision_count || Configuration.get_config_value('PrecisionCount')
      @precision_count = calculate_precision @precision_count
    end

    def set_precision_count new_count=nil
      new_count ||= Configuration.get_config_value('PrecisionCount')
      @precision_count = calculate_precision new_count
    end

    def calculate_precision val # limits precision, 2 <= precision <= 4
      val = val.to_i < 2 ? 2 : val.to_i > 4 ? 4 : val.to_i
    end
  end

end