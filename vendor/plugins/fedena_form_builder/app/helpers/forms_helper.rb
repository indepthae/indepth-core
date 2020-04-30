module FormsHelper
  def render_field field,params = {},error = false,edit = false ## render field in form view
    field_label = ""
    field_tag = ""
    opening_field_block = "<div class='field_block'>"
    label_opening_block = "<div class='label_text_field'>"
    field_opening_block = "<div class='input_text_field'>"
    field_opening_block2 = "<div>"
    closing_block =  "</div>"
    options = ""
    cnt = 0
    settings = field.field_settings.present? ? JSON.parse(field.field_settings) : []
    setting = []
    unless(settings.present?)
      desc_label = ""
    else
      desc_label = "<div class='description_label'>#{settings['description'].present? ? settings['description'] : ''}</div>"

      setting << 'mandatory' if (settings['mandatory'].present? and settings['mandatory'] == 'true')
      setting << 'fieldWithErrors' if error
    end
        
    case field.field_type
    when 'select'
      label_block = label_tag("form_select_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      opt_array = []
      field.form_field_options.collect { |x| opt_array << [x.label,{:attr_data=> x.weight},x.value]}      
      if edit
        field_block = select_tag("form[select][#{field.id}][value]",options_for_select(field.form_field_options.map{ |item| [item.label,"#{item.value}:field_option_id#{item.id}:field_option_weight#{item.weight}"]},["#{params['value']}:field_option_id#{params['option_id']}:field_option_weight#{params['weight']}"])).html_safe
      else
        field_block = select_tag("form[select][#{field.id}][value]",options_for_select(field.form_field_options.map{ |item| [item.label,"#{item.value}:field_option_id#{item.id}:field_option_weight#{item.weight}"]})).html_safe
      end     
      
      weight_field = hidden_field_tag("form[select][#{field.id}][option_id]",'')
      label_field = hidden_field_tag("form[select][#{field.id}][label]",field.label)
      field_tag = label_opening_block + label_block + weight_field + label_field + closing_block + field_opening_block + field_block + closing_block
      return opening_field_block + field_tag + closing_block
    when 'checkbox'
      selected_options = params['value'].present? ? params['value'].collect { |x,y| x} : []
      label_block = label_tag("select_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      label_field = hidden_field_tag("form[checkbox][#{field.id}][label]",field.label)
      field.form_field_options.each do |opt|
        cnt = cnt.next
        options += field_opening_block
        options += check_box_tag("form[checkbox][#{field.id}][value][#{opt.id}]","#{opt.value}",(selected_options.include? opt.id.to_s)).html_safe
        options += label_tag("form_checkbox_#{field.id}_value_#{opt.id}","#{opt.label}").html_safe
        options += closing_block
      end      
      field_tag = label_opening_block + label_block + label_field + closing_block + options
      return opening_field_block + field_tag + closing_block
    when 'radio'
      selected = (params['option_id'].present? ? params['option_id'] : '')
      label_block = label_tag("select_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      weight_field = hidden_field_tag("form[radio][#{field.id}][weight]",'')
      label_field = hidden_field_tag("form[radio][#{field.id}][label]",field.label)
      option_selection_field = hidden_field_tag("form[radio][#{field.id}][option_id]",selected)
      
      field.form_field_options.each do |opt|
        cnt = cnt.next
        options += field_opening_block
        if(edit)
          options += radio_button_tag("form[radio][#{field.id}][value]",opt.value,(selected == opt.id.to_s ? true : false),:attr_self=>field.id,:attr_id => opt.id,:attr_data => opt.weight)
        else
          options += radio_button_tag("form[radio][#{field.id}][value]",opt.value,(selected == opt.id.to_s ? true : false),:attr_self=>field.id,:attr_id => opt.id,:attr_data => opt.weight)
        end
        
        options += label_tag("form_radio_#{field.id}_#{opt.label.strip.downcase.gsub(' ','_')}","#{opt.label}").html_safe        
        options += closing_block
      end
      field_tag = label_opening_block + option_selection_field + label_block + label_field + closing_block + options
      return opening_field_block + field_tag + closing_block
    when 'text'
      label_block = label_tag("text_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      label_field = hidden_field_tag("form[text][#{field.id}][label]",field.label)
      field_block = text_field_tag("form[text][#{field.id}][value]",params['value']).html_safe      
    when 'textarea'
      label_block = label_tag("textarea_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      label_field = hidden_field_tag("form[textarea][#{field.id}][label]",field.label)
      field_block = text_area_tag("form[textarea][#{field.id}][value]",params['value']).html_safe
    when 'file'
      label_block = label_tag("file_#{field.id}",field.label,:class=>"#{setting.join(' ')}") + desc_label
      label_field = hidden_field_tag("form[file][#{field.id}][label]",field.label)
      field_block = file_field_tag("files[#{field.id}][value]").html_safe
    when 'hr'
      field_block = "<hr/>"
      return field_block
    end
    field_tag = label_opening_block + label_block + label_field + closing_block + field_opening_block + field_block + closing_block
    return opening_field_block + field_tag + closing_block
  end
end
