# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Reports
    module TemplatePHelper
      
      def custom_report_header(values,options={})
        font_family = options[:font_family] if options.present?
        html="<div class='header'>
          <div class='two columns right_text'>
            <div class='logo' style=\"background-image:url(\'#{values[:logo2_url].to_s}\')\"></div>
          </div>              
          <div class='eight columns center_text'>"
        html += (font_family.present?) ? "<div class='school_name' style='font-family: #{font_family};'>" :"<div class='school_name'>"
        html += "#{values[:school_name].to_s}
            </div>
            <div class='school_address'>
              #{values[:school_address].to_s}
              #{values[:school_email_with_website]}
            </div>
          </div>
          <div class='two columns left_text'>
            <div class='logo' style=\"background-image:url(\'#{values[:logo1_url].to_s}\')\"></div>
          </div>              
        </div>"
        return html
      end      
      
    end
  end
end
