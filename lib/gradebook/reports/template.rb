module Gradebook
  module Reports
    class Template

      # Template.config do
      #   name 'template_1'
      #   target_type :school
      #   schools [11,22]
      #
      #   setting do
      #     name 'logo'
      #     type :hash # :text, :hash, :array
      #     options {'cbse' => assets_path + "cbselogo.jpg", 'icse' => assets_path + "icselogo.jpg"}
      #   end
      #
      #   setting do
      #     name 'details_mode'
      #     type :array # :text, :hash, :array
      #     options ['simple', 'extended']
      #   end
      #
      # end

      TEMPLATES_DIR = File.join(Rails.root,"vendor/plugins/gradebook_templates")

      class << self
        attr_accessor :templates, :loaded_templates

        # resets the templates collection, loads each of templates to the collection
        def init
          @templates = []# GradebookTemplate.all
          @loaded_templates = GradebookTemplate.all 
          load_templates
        end

        # loads each of templates to the collection
        def load_templates
          template_entries = Dir.entries("#{TEMPLATES_DIR}")
          template_entries.delete "."
          template_entries.delete ".."
          template_entries.each do |entry|
            load "#{TEMPLATES_DIR}/#{entry}/config.rb"
          end
        end

        # dsl for configuring each template
        def config (&block)
          template = new
          template.instance_eval &block
          validate_and_add template
        end

        # validations, 1. no two templates with same name. More might come
        def register (template)
          temp = loaded_templates.find{|entry| entry.name == template.name}
          if temp.nil?
            temp = GradebookTemplate.add_template(template)
            loaded_templates << temp
          else
            temp.validate_and_update(template)
          end
          
          temp
        end
        
        def validate_and_add (template)
          templates << template if templates.find{|entry| entry.name == template.name}.nil?
          template
        end
        
        def reset(template_name = nil)
          if template_name.present?
            template = templates.find{|entry| entry.name == template_name}
            if template.present?
              register(template) 
              template
            end
          else
            templates.each {|entry| register(entry) }
          end
        end

      end

      attr_accessor :settings

      def initialize
        @settings = []
      end
      
      def add_or_reset
        self.class.register(self)
      end

      # dsl method for adding settings
      def setting (&block)
        template_setting = TemplateSetting.new
        template_setting.instance_eval &block
        @settings << template_setting
      end

      # resolves the values stored for a specific template's settings at school->planner level
      # expecting an array of hash with :name, :value keys for a single setting's name and it user given value
      def resolve_template_settings (setting_values)
        # tbd
      end

      # get settings of this template stored for an individual report planner
      def settings_values_for (planner)
        AssessmentReportSetting.all_settings(planner)
      end
      
      # path to folder where template definitions are stored
      def template_folder_path
        if is_default
          File.join(Rails.root,"app/views/default_reports")
        else
          File.join(TEMPLATES_DIR, name)
        end
      end

      # path to folder where template views are stored
      def template_view_folder_path
        File.join(template_folder_path, 'templates')
      end
      
      # path to template preview image
      def template_preview_path
        File.join(template_folder_path,"assets","preview.png")
      end

      # get specific pdf options from the config
      def pdf_options
        # tbd
      end
      
      # returns config path
      def config_path
        "#{TEMPLATES_DIR}/#{name}/config.rb"
      end
      
      def config_checksum
        Digest::SHA1.file(config_path).hexdigest
      end
      
      def settings_keys
        settings.collect(&:name).map{|s| "#{name}_#{s}".camelize}
      end
      
      def template_properties_as_hash
        hash = {}
        instance_variables.each do |a|
          next if a == '@settings' 
          hash[a[1..-1].to_sym] =  instance_variable_get("#{a}")
        end

        hash
      end
      
      def loaded?
        self.class.loaded_templates.find{|entry| entry.name == name}.present?
      end
      
      def changed?
        load_template = self.class.loaded_templates.find{|entry| entry.name == name}
        config_checksum != load_template.file_checksum
      end
      
      def is_active?
        load_template = self.class.loaded_templates.find{|entry| entry.name == name}
        load_template.is_active
      end
      
      def helper_name
        'Gradebook::Reports::' + (name + '_helper').camelize
      end
      
      def helper_present?
        File.exists?(helper_path)
      end
      
      def helper_module
        helper_present? and load(helper_path) and (helper_name.constantize rescue false)
      end
      
      def helper_path
        File.join(template_folder_path, name + '_helper' + '.rb' )
      end

      private

      # saving some lines of code in writing dsl methods for attributes
      def method_missing (method_name, *args, &block)

        if [:name, :target_type, :schools, :is_default, :display_name, :description].include? method_name
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