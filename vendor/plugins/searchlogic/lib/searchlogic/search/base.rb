module Searchlogic
  class Search
    module Base
      def self.included(klass)
        klass.class_eval do
          attr_accessor :klass, :current_scope
          undef :id if respond_to?(:id)
        end
      end
      
      # Creates a new search object for the given class. Ex:
      #
      #   Searchlogic::Search.new(User, {}, {:username_like => "bjohnson"})
      def initialize(klass, current_scope, conditions = {})
        self.klass = klass
        self.current_scope = current_scope
        @conditions ||= {}
        self.conditions = replace_dotted conditions if conditions.is_a?(Hash)
      end

      # For dotted string comparisons
      def replace_dotted conditions
        conditions.each do |key, value|
          if value.is_a?(String) && value.index('.') && key.to_s =~ /(.*)(equals|like|begins_with)$/
            conditions.merge!($1+'dotted_'+$2=>value.gsub(".", "&dot;"))
            conditions.delete key
          end
        end
        conditions
      end

      def clone
        self.class.new(klass, current_scope && current_scope.clone, conditions.clone)
      end
    end
  end
end