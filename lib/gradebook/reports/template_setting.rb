module Gradebook
  module Reports
    class TemplateSetting

      def assets_path
        "assets/"
      end
      
      def method_missing (method_name, *args, &block)

        if [:name, :kind, :options, :default_value].include? method_name
          if args[0].nil?
            instance_variable_get("@#{method_name}")
          else
            instance_variable_set("@#{method_name}", args[0])
          end
        else
          super
        end

      end
    end
  end
end