module Gradebook

  ##
  # Helper to implement rounding of scores based on the report settings.
  # Provides methods that can be included in classes applicable
  module Rounding

    ##
    # Callback for include. We extend the ClassMethods module which contain the macros to be used in classes.
    def self.included (klass)
      klass.instance_eval do
        extend ClassMethods
      end
    end

    ##
    # method to be used in other classes, this will round off and strip any trailing zeroes from the +value+
    def gb_round_off(value)
      gb_remove_trailing_zero(gb_round_off_score(value.to_f))
    end

    private

    ##
    # rounds off the score based on the gb_round_off_value
    def gb_round_off_score (value)
      return value if Integer === value || value.blank?
      return value unless gb_round_off_size
      value = value.round(gb_round_off_size)
      value
    end

    ##
    # Removes trailing zero after decimal point
    def gb_remove_trailing_zero (value)
      (value == value.to_i) ? value.to_i : value
    end

    ##
    # Use this block method to set and unset the round of size via Thread.current
    def with_round_off_size (size, &block)
      Thread.current[:gb_round_of_size] = size
      yield block
    ensure
      Thread.current[:gb_round_of_size] = nil
    end

    ##
    # getter for the current round off size. Returns nil if rounding is not enabled else returns the size.
    # rounding size can be set via Thread.current[:gb_round_of_size] as well. Make sure the value cleaned afterwards
    def gb_round_off_size
      @round_off ||= (
          if Thread.current[:gb_round_of_size].present?
            Thread.current[:gb_round_of_size]
          else
            settings = Components.settings || {}
            if settings[:enable_rounding].to_i == 1
              settings[:rounding_size].to_i || 1
            else
              false
            end
          end
      )
      @round_off
    end

    ##
    # Module extends the macros to declare the properties which is to be rounded
    module ClassMethods

      private

      ##
      # This is a macro. Declares which properties are to be rounded off.
      # @param properties List of properties to be rounded off.
      # Options :
      # * +if+ takes a proc and evaluates against the object. Expects to return boolean
      # Example: round_off_properties :prop_1, :prop_2
      #          round_off_properties :prop_1, :prop_2, :if => Proc.new { dirty? }
      def round_off_properties (*properties)
        # Takes the properties to be rounded, uses alias_method_chain and overrides the setter.
        options = properties.extract_options!
        instance_eval do
          properties.each do |property|
            _gb_override_property(property, options)
          end
        end
      end

      ##
      # Overrides the property setter to implement rounding
      def _gb_override_property (property, options)
        property_setter = "#{property}="
        property_setter_alias_with = "#{property}_with_rounding="
        property_setter_alias_without = "#{property}_without_rounding="

        # dynamic method creation which overrides the the property setter, returns the rounded value based on
        #  options.
        define_method  property_setter_alias_with do |arg|
          if options[:if].nil? or self.instance_eval(&options[:if])
            send property_setter_alias_without, gb_remove_trailing_zero(gb_round_off_score(arg))
          else
            send property_setter_alias_without, gb_remove_trailing_zero(arg)
          end
        end

        alias_method_chain property_setter, 'rounding'
      end

    end

  end
end