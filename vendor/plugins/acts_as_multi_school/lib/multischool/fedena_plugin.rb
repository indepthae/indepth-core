module MultiSchool
  module FedenaPluginWrapper
    def self.included(base)
      base.extend ClassMethods
      base.const_set("MULTI_SCHOOL_MODELS",[])
      base.const_set("MULTI_SCHOOL_CLASSES",[])
      base.const_set("MULTI_SCHOOL_CONTROLLERS",{})
      base.const_set("GENERAL_MODELS",[])
      base.class_eval do
        class << self
          alias_method_chain :register=, :multi_school
          alias_method_chain :accessible_plugins, :multi_school
        end
      end
    end
  
    module ClassMethods
      
      def register_with_multi_school=(plugin_details)
        send :register_without_multi_school=, (plugin_details)
        if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name]}.include?(plugin_details[:name])
          FedenaPlugin::MULTI_SCHOOL_MODELS << plugin_details[:multischool_models] unless plugin_details[:multischool_models].blank?
          FedenaPlugin::GENERAL_MODELS << plugin_details[:general_models] unless plugin_details[:general_models].blank?
          FedenaPlugin::MULTI_SCHOOL_CLASSES << plugin_details[:multischool_classes] unless plugin_details[:multischool_classes].blank?
          FedenaPlugin::ADDITIONAL_LINKS[:multi_school_settings_hook] << plugin_details[:multi_school_settings_hook] unless plugin_details[:multi_school_settings_hook].blank?
        end
      end

      def load_plugin_seed_data
        FedenaPlugin::AVAILABLE_MODULES.each do |m|
          seed_file = File.join(Rails.root,"vendor/plugins/#{m[:name]=='fedena_google_sso' ? 'fedena_oauth' : m[:name]}" ,'db', 'seeds.rb')
          load(seed_file) if File.exist?(seed_file)
        end
      end

      def accessible_plugins_with_multi_school
        raise MultiSchool::Exceptions::SchoolNotSelected, "School not selected" unless MultiSchool.current_school
        accessible_plugins_without_multi_school & MultiSchool.current_school.available_plugins | non_selectable_plugins
      end
      
      def multischool_models_for (plugin)
         FedenaPlugin::AVAILABLE_MODULES.find{|s| s[:name]==plugin.to_s}.try '[]', :multischool_models || []
      end

      def general_models_for (plugin)
         FedenaPlugin::AVAILABLE_MODULES.find{|s| s[:name]==plugin.to_s}.try '[]', :general_models || []
      end

      def selectable_plugins
        FedenaPlugin::AVAILABLE_MODULES.select{|s| !s[:no_select] }.collect{|s| s[:name]}
      end

      def non_selectable_plugins
        FedenaPlugin::AVAILABLE_MODULES.select{|s| s[:no_select]==true }.collect{|s| s[:name]}
      end
      
    end
  end
  
end
