require 'combine_pdf'
module Gradebook
  module Reports
    class Renderer

      DEFAULT_TEMPLATE_DIR = File.join(Rails.root,'vendor', 'plugins','gradebook_templates')

      attr_accessor :report, :template, :controller, :planner,:report_model_obj

      def self.render (report, template, planner,report_model_obj)
        renderer = new(report, template, planner,report_model_obj)
        renderer.make_pdf_string
      end

      def initialize (report, template, planner,report_model_obj)
        @report  = report
        @planner = planner
        @template = template
        @report_model_obj = report_model_obj
        @controller = PdfController.new
        prepare_controller
      end

      def make_pdf_string
        # controller.instance_eval do
        #   @report = report.component_data
        #   @settings = template.settings_values_for(report)
        # end
        set_properties_on_controller
        
        #        container_str = make_container
        container_str = nil
        content_str = make_content
        watermark_str = watermark_enabled ? make_watermark : nil
          
          #    content_str
          #        template.is_default ? content_str :
          merge_content_and_container_and_watermark(content_str, container_str, watermark_str)        
        end
      
    def watermark_enabled
      return false if report.report_template.nil?
      template_settings = template.settings_values_for(planner)
      key = report.report_template.to_s + "_watermark"
      if template_settings[key.to_sym].present?
        return  template_settings[key.to_sym] == "enable" ? true : false
      else
        return false
      end
    end
    
    def make_content   
      template_settings = template.settings_values_for(planner)
      key = report.report_template.to_s + "_margin"
      custom_margin = false 
      if template_settings[key.to_sym].present?
        margin_top = 10
        margin_bottom = 10 
        case template_settings[key.to_sym]
        when "low"
          margin_top = 2
          margin_bottom = 2 
          custom_margin = true
        when "high"
          custom_margin = true
          margin_top = 15
          margin_bottom = 15 
        end
      end
      if custom_margin
        pdf_string = controller.send :render_to_string, {:template=>"templates/base" , :pdf=>"pdf_name.pdf",:margin=>{:top=>margin_top,:bottom=>margin_bottom}}.merge({:layout => 'custom_pdf.html'}) 
      else
        pdf_string = controller.send :render_to_string, {:template=>"templates/base" , :pdf=>"pdf_name.pdf"}.merge({:layout => 'custom_pdf.html'})
      end
      controller.send :clean_temp_files
      
      pdf_string
    end
    
      def make_container
        return if template.is_default
        
        pdf_string = controller.send :render_to_string, {:template=>"templates/container" , :pdf=>"pdf_name.pdf", :margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0}}.merge({:layout => 'custom_pdf.html'})

        controller.send :clean_temp_files

        pdf_string
      end
      
      
      def make_watermark
        return if template.is_default
         
        pdf_string = controller.send :render_to_string, {:template=>"templates/watermark" , :pdf=>"pdf_name.pdf", :margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0}}.merge({:layout => nil})

        controller.send :clean_temp_files

        pdf_string
      end
      
      def merge_content_and_container_and_watermark (content_str, container_str, watermark_str)
        content_pdf = pdf_obj_from_string(content_str)
        final_pdf = CombinePDF.new
        if container_str.present?
          container = pdf_obj_from_string(container_str).pages[0]
          content_pdf.pages.each{|page| x = container.dup ; x.extend(CombinePDF::Page_Methods) ; final_pdf << x }
          final_pdf.pages.each_with_index{|page,index| page << content_pdf.pages[index] }
        else
          content_pdf.pages.each{|page| final_pdf << page }
        end
        if watermark_str.present?
          watermark = pdf_obj_from_string(watermark_str).pages[0]
          final_pdf.pages.each {|page| page << watermark}
        end
          
        final_pdf.to_pdf
      end
      
      def pdf_obj_from_string (pdf_string)
        CombinePDF::PDF.new(CombinePDF::PDFParser.new(pdf_string))
      end


      private
      
      def set_properties_on_controller
        controller.instance_variable_set(:@report, report)
        controller.instance_variable_set(:@report_model_obj, report_model_obj)
        controller.instance_variable_set(:@report_template, template)
        controller.instance_variable_set(:@settings, template.settings_values_for(planner))
      end

      def prepare_controller

        controller.response = ActionController::Response.new()
        controller.request = Rack::Request.new({})
        av = ActionView::Base.new(ActionController::Base.view_paths.unshift(template.template_folder_path), {}, controller)
        av.instance_variable_set(:@template_format, :html)
        controller.response.template = av
        controller.instance_variable_set(:@template, av)
        controller.session = {}
        controller.params = {}
        helper_module = template.helper_module 

        av.class_eval do
          include ActionView::Helpers
          include WickedPdfHelper
          include TemplateHelper
          include ApplicationHelper
          include helper_module if helper_module
        end
      end
      
    end
  end
end