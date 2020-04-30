module AssessmentReportsHelper
  def fetch_report_generation_path(report, course)
    
    case report.class.to_s
    when 'AssessmentPlan'
      generate_planner_reports_assessment_reports_path(:assessment_plan_id => report.id, :course_id => course.id)
    when 'AssessmentTerm'
      generate_term_reports_assessment_reports_path(:term_id => report.id, :course_id => course.id)
    else
      generate_exam_reports_assessment_reports_path(:group_id => report.id, :course_id => course.id)
    end
  end
  
  def load_preview_path(template)
      template.template_preview_path
  end
  
  def preview_thumb_for(template)
#    path = load_preview_path(template.try(:template))
#    image_tag("/assessment_reports/preview_img/?name=#{template.name}", :class => "preview_thumb")
    html = "<div class='preview_thumb' style=\"background-image:url('/assessment_reports/preview_img/?name=#{template.name}')\">
                </div>"
    html
  end
  
  def link_to_add_remark_set(name,form,association,partial,target_type)
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :f => builder, :target_type => target_type)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img add-icon-link-width remark-set-name-label"})
  end
  
  def settings_fields_for(template)
    template.settings.each do |setting|
      setting_name = "#{template.name}_#{setting.name}".to_sym
      content_tag_concat :div, :class=>'label_field_pair template_field_pair' do
        content_tag_concat :label, setting.name.gsub(/_/, ' ').camelize,:class => 'template_label rpset'
        content_tag_concat :div, :class=>'label-field-pair' do
          case setting.kind
          when :select
            select :assessment_report_setting, setting_name, options_for_select(setting.options.map{|p| p.is_a?(Array) ? [p.first, p.second] : [p, p]}, (setting_name.to_s =~ /logo/).to_i > 0 ? @setting[setting_name] : (@setting[setting_name].blank? ? setting.default_value : @setting[setting_name]) ),
                      {}, {:class => 'core_field rpset'}
          when :text
            text_field :assessment_report_setting, setting_name, :value => (@setting[setting_name] || setting.default_value), :class => 'text_field rpset'
          end
        end
      end
    end
  end
  
  def content_tag_concat (*args, &block)
    concat(content_tag *args, &block)
  end
  
end
