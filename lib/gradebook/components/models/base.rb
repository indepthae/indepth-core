module Gradebook
  module Components
    module Models
      class Base
        
        # extend ExecutionHooks
        
        ##
        # Setting instance variables on all attributes passed for initialization
        # Params:
        # => attributes (.: key-value pairs)
        # Example: new(:name => 'John Deo', :age => 25)
        def initialize(attributes)
          attributes.each do |attribute_name, attribute_value|
            self.instance_eval{send "#{attribute_name}=", attribute_value}
          end
        end
        
        ##
        # returns all properties of a component as array.
        def properties
          self.class.get_properties
        end
        
        class << self
          
          ##
          # Setting properties of a component. A property will be accessible with
          # a component object. Can pass multiple params which we need to set as 
          # a property.
          # Example =>  properties :name, :age
          def properties(*attributes)
            attributes.each do |attribute_name|
              class_eval {attr_accessor attribute_name}
            end
          end
          
          ##
          # returns all properties of a component as array.
          def get_properties
            instance_methods.each_with_object([]) { |key, acc| acc << key.to_s.gsub(/=$/, '') if key.match(/\w=$/) }
          end
        end
      end
    end
  end
end