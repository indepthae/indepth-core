module AssessmentsHelper
  def attribute_linking_link_name(batch,ag)
    attribute_assessment_present?(batch,ag) ? t('edit_attributes') : t('link_attributes')
  end
  
  def assessment_activated?(batch,ag,type)
    if type.subject_attribute or type.subject_wise_attribute
      AssessmentGroupBatch.batch_attribute_assessments(batch,ag).count > 0
    elsif type.subject
      AssessmentGroupBatch.batch_subject_assessments(batch,ag).count > 0
    else
      AssessmentGroupBatch.batch_actvity_assessments(batch,ag).count > 0
    end
  end
  
  def marks_entered?(batch,ag,type)
    if type.subject_attribute or type.subject_wise_attribute
      AssessmentGroupBatch.batch_attribute_assessments_with_marks(batch,ag).count > 0
    elsif type.subject
      AssessmentGroupBatch.batch_subject_assessments_with_marks(batch,ag).count > 0
    else
      AssessmentGroupBatch.batch_actvity_assessments_with_marks(batch,ag).count > 0
    end
  end
  
  def list_assessments(type,assessments, batch, assessment_group, inactive_subjects)
    if type.activity
      render :partial => "activity_assessments_list", :locals=>{:assessments=>assessments, :batch => batch , :assessment_group => assessment_group}
    elsif type.subject_attribute or type.subject_wise_attribute
      render :partial => "attribute_assessments_list", :locals=>{:assessments=>assessments, :batch => batch, 
        :assessment_group => assessment_group, :inactive_subjects => inactive_subjects}
    elsif type.subject
      render :partial => "subject_assessments_list", :locals=>{:assessments=>assessments, :batch => batch, :assessment_group => assessment_group}
    end
  end
  
  def link_to_add_assessment_fields(name, c, association, partial)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial + "_fields", :c => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end
  
  def skill_name_with_marks(skill,group)
    if group.grade_type?
      skill.try(:name)
    else
      "#{skill.try(:name)} &#x200E;(#{skill.maximum_marks.to_f})&#x200E;"
    end
  end
  
  def grouped_options_for_select_with_option_new(grouped_options, selected_key = nil, prompt = nil)
    body = ''
    body << content_tag(:option, prompt, :value => "") if prompt
    grouped_options = grouped_options.sort if grouped_options.is_a?(Hash)
    grouped_options.each do |group|
      if group[1].is_a? Array
        body << content_tag(:optgroup, options_for_select(group[1], selected_key), :label => group[0])
      else
        body << content_tag(:option, group[0], :value => group[1])
      end
    end
    body
  end
 
  def grouped_options_for_select_with_option_edit(grouped_options, selected_key = nil, disabled = nil, prompt = nil)
    body = ''
    body << content_tag(:option, prompt, :value => "") if prompt
    grouped_options = grouped_options.sort if grouped_options.is_a?(Hash)
    grouped_options.each do |group|
      if group[1].is_a? Array
        body << content_tag(:optgroup, options_for_select_with_option(group[1], selected_key, disabled), :label => group[0])
      else
        if selected_key == group[1]
          body << content_tag(:option, group[0], :value => group[1], :selected => true, :disabled => (disabled.include? group[1]) )
        else
          body << content_tag(:option, group[0], :value => group[1], :disabled => (disabled.include? group[1]))
        end
      end
    end
    body
  end
  
  def options_for_select_with_option(container, selected = nil, disabled = nil)
    return container if String === container

    container = container.to_a if Hash === container
    selected = extract_selected_and_disabled(selected)

    options_for_select = container.inject([]) do |options, element|
      text, value = option_text_and_value(element)
      selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
      disabled_attribute = ' disabled="disabled"' if disabled && option_value_selected?(value, disabled)
      options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}#{disabled_attribute}>#{html_escape(text.to_s)}</option>)
    end

    options_for_select.join("\n").html_safe
  end
  
end
