module FormTemplatesHelper

  def render_field_for_edit obj, ts ## renders field in form template design area for edit purpose
    #    ts = Time.now.to_i
    obj_settings = JSON.parse(obj.field_settings) if (obj.field_settings.is_a? String)
    obj_settings = obj.field_settings if (obj.field_settings.is_a? Hash)
    opening_field_block = "<div id='field_block_#{obj.id}' class='field_block field_#{obj.field_type}' attr-type='"+obj.field_type+"'>"
    closing_block =  "</div>"
    delete_field = "<div class='delete_field' attr_message='#{t('confirm_delete')}'></div>"    
    desc_text = obj_settings['description'].present? ? obj_settings['description'] : ''
    desc_block = "<div id='description_label_#{obj.id}' class='description_label'>#{desc_text}</div>"
    cnt = 0
    main_label_class = ['main_label']
    main_label_class << 'mandatory' if (obj_settings['mandatory'].present? and obj_settings['mandatory']=='true')
    mandatory = (obj_settings['mandatory'].present? and obj_settings['mandatory']=='true') ? true : false
    case obj.field_type
    when 'text' ## text field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("text_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = text_field_tag("form_template[text][#{ts}]").html_safe
      field  = label_opening_block + label_block + desc_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'textarea' ## textarea field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("textarea_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = text_area_tag("textarea_#{ts}").html_safe
      field  = label_opening_block + label_block + desc_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'file' ## file field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("file_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = file_field_tag("file_#{ts}").html_safe
      field  = label_opening_block + label_block + desc_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'radio' ## radio field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("checkbox_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe      
      option_block = ""
      obj.form_field_options.each do |field_option|
        cnt = cnt.next
        option_block += field_opening_block
        option_block += radio_button_tag("option_#{field_option.id}","#{field_option.label}",false,:data_weight=>field_option.weight).html_safe
        option_block += label_tag("#{field_option.id}","#{field_option.label}").html_safe
        option_block += closing_block
      end
      field  = label_opening_block + label_block + desc_block + closing_block
      field += option_block #+ closing_block
    when 'checkbox' ## checkbox field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("checkbox_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe      
      option_block = ""
      obj.form_field_options.each do |field_option|
        cnt = cnt.next
        option_block += field_opening_block
        option_block += check_box_tag("option_#{field_option.id}","#{field_option.label}",false,:data_weight=>field_option.weight).html_safe
        option_block += label_tag("#{field_option.id}","#{field_option.label}").html_safe
        option_block += closing_block
      end
      field  = label_opening_block + label_block + desc_block + closing_block
      field += option_block #+ closing_block
    when 'select' ## select field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("select_#{ts}", obj.label,:class => main_label_class.join(' '),:attr_mandatory => mandatory).html_safe
      option_block = []
      obj.form_field_options.each do |field_option|
        unless field_option.new_record?
          option_block.push ["#{field_option.label}","#{field_option.label}:field_option_id#{field_option.id}_field_option_weight#{field_option.weight}"]
        end
      end
      field_block = select_tag("select_#{ts}",options_for_select(option_block)).html_safe
      field  = label_opening_block + label_block + desc_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'hr'
      field_opening_block = "<div class='horizontal_break'>"
      field_block = '<hr/>'
      field = field_opening_block + field_block + closing_block
    end
    return opening_field_block + field + delete_field + closing_block
  end
  
  def render_field field ## renders a field for template view
    field_label = ""
    field_tag = ""
    opening_field_block = "<div class='field_block'>"
    label_opening_block = "<div class='label_text_field'>"
    field_opening_block = "<div class='input_text_field'>"
    field_opening_block2 = "<div>"
    closing_block =  "</div>"
    options = ""
    cnt = 0
    settings = JSON.parse(field.field_settings)
    desc_label = "<div class='description_label'>#{settings['description'].present? ? settings['description'] : ''}</div>"
    case field.field_type
    when 'select'
      label_block = label_tag("select_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true' ? 'mandatory':''}") + desc_label
      field_block = select_tag("select_#{field.id}",options_for_select(field.form_field_options.map(&:value))).html_safe      
    when 'checkbox'
      label_block = label_tag("checkbox_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true'  ? 'mandatory':''}") + desc_label
      field.form_field_options.each do |opt|
        cnt = cnt.next
        options += field_opening_block
        options += check_box_tag("option_#{field.id}_#{cnt}","#{opt.value}",false).html_safe
        options += label_tag("option_#{field.id}_#{cnt}","#{opt.label}").html_safe
        options += closing_block
      end
      field_tag = label_opening_block + label_block + closing_block + options
      return opening_field_block + field_tag + closing_block
    when 'radio'
      label_block = label_tag("radio_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true' ? 'mandatory':''}") + desc_label
      field.form_field_options.each do |opt|
        cnt = cnt.next
        options += field_opening_block
        options += radio_button_tag("option_#{field.id}",opt.value,false).html_safe
        options += label_tag("option_#{field.id}_#{opt.label.downcase.gsub(' ','_')}","#{opt.label}").html_safe        
        options += closing_block
      end
      field_tag = label_opening_block + label_block + closing_block + options
      return opening_field_block + field_tag + closing_block
    when 'text'
      label_block = label_tag("text_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true' ? 'mandatory':''}") + desc_label
      field_block = text_field_tag("text_#{field.id}").html_safe      
    when 'textarea'
      label_block = label_tag("textarea_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true' ? 'mandatory':''}") + desc_label
      field_block = text_area_tag("textarea_#{field.id}").html_safe
    when 'file'
      label_block = label_tag("file_#{field.id}",field.label,:class=>"#{settings['mandatory'].present? and settings['mandatory'] == 'true' ? 'mandatory':''}") + desc_label
      field_block = file_field_tag("file_#{field.id}").html_safe
    when 'hr'
      field_block = "<hr/>"
      return field_block
    end
    field_tag = label_opening_block + label_block + closing_block + field_opening_block + field_block + closing_block
    return opening_field_block + field_tag + closing_block
  end
  
  def add_option params ## adds option for radio or checkbox or select field
    ts = params[:ts]
    cnt = params[:cnt].next
    field_type = params[:field_type]
    field_opening_block = "<div class='field'>"
    field_opening_block2 = "<div class='input_text_field'>"
    option_field_opening = "<div class='option_field'>"
    option_field_opening_block = "<div class='small-field'>"
    option_weight_opening_block = "<div class='smaller-field'>"
    link_opening_block = "<div class='add_option'>"
    option_label = "<label>Options</label>"
    closing_block =  "</div>"
    settings_block_opening = "<div id='settings'>"
    content_block_opening = "<div id='field_content'>"
    link_div = "<div id='ajax_link'>"
    case field_type
    when 'select'
      delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt.to_i.pred}'>"
      name = "option_#{ts}_#{cnt}"
      field_weight_block = text_field_tag("weight_#{name}","",:attr_no => cnt.to_i.pred, :attr_type => field_type, :placeholder => t('weight')).html_safe
      field_block = text_field_tag(name,"Option #{cnt}",:attr_no => cnt.to_i.pred, :attr_type => field_type).html_safe
      field = settings_block_opening
      field += option_field_opening + option_field_opening_block + field_block +
        closing_block + option_weight_opening_block + field_weight_block + closing_block +
        delete_link_block_opening + closing_block + closing_block + closing_block

        
      option_block = "<option value='Option #{cnt}' attr_life='new'>Option #{cnt}</option>"
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>ts,:field_type=>field_type},:html =>{:class => "themed_text"},:success => "add_new_option();")
      field += link_div + add_link_block + closing_block
      field += content_block_opening + option_block + closing_block
    when 'radio'
      delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt.to_i.pred}'>"
      name = "option_#{ts}_#{cnt}"
      field_weight_block = text_field_tag("weight_#{name}","",:attr_no => cnt.to_i.pred, :attr_type => field_type, :placeholder => t('weight')).html_safe
      field_block = text_field_tag(name,"Option #{cnt}",:attr_no => cnt.to_i.pred, :attr_type => field_type).html_safe
      field = settings_block_opening
      field += option_field_opening + option_field_opening_block + field_block +
        closing_block + option_weight_opening_block + field_weight_block + closing_block +
        delete_link_block_opening + closing_block + closing_block + closing_block
        
      option_block = field_opening_block2
      option_block += radio_button_tag("option_#{ts}","Option #{cnt}",false,:disabled=>'disabled',:attr_life=>'new').html_safe
      option_block += label_tag("option_#{ts}","Option #{cnt}").html_safe
      option_block += closing_block
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>ts,:field_type=>field_type},:html =>{:class => "themed_text"},:success => "add_new_option();")
      field += link_div + add_link_block + closing_block
      field += content_block_opening + option_block + closing_block

    when 'checkbox'
      delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt.to_i.pred}'>"
      name = "option_#{ts}_#{cnt}"
      field_weight_block = text_field_tag("weight_#{name}","",:attr_no => cnt.to_i.pred, :attr_type => field_type, :placeholder => t('weight')).html_safe
      field_block = text_field_tag(name,"Option #{cnt}",:attr_no => cnt.to_i.pred, :attr_type => field_type).html_safe
      field = settings_block_opening
      field += option_field_opening + option_field_opening_block + field_block +
        closing_block + option_weight_opening_block + field_weight_block + closing_block +
        delete_link_block_opening + closing_block + closing_block + closing_block

      option_block = field_opening_block2
      option_block += check_box_tag("option_#{ts}","Option #{cnt}",false,:disabled=>'disabled',:attr_life=>'new').html_safe
      option_block += label_tag("option_#{ts}","Option #{cnt}").html_safe
      option_block += closing_block
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>ts,:field_type=>field_type}, :html =>{:class => "themed_text"},:success => "add_new_option();")
      field += link_div + add_link_block + closing_block
      field += content_block_opening + option_block + closing_block
    end
    return field
  end
  
  def render_settings params,action_type ## loads settings of a field in form template design area
    opening_setting_block = ""
    opening_field_block = "<div class='field-label'>"
    opening_field_block2 = "<div class='field-label textarea_height'>"
    label_opening_block = "<div class='label_field'>"
    label_block = "<label>Label</label>"
    mandatory_label = "<label>#{t('type')}</label>"
    mandatory_text_label = "<label for=mandatory_#{params['id']}>#{t('mandatory')}</label>"
    desc_label = "<label>#{t('label_description')}</label>"
    field_opening_block = "<div class='field'>"
    option_field_opening_block = "<div class='small-field'>"
    option_weight_opening_block = "<div class='smaller-field'>"
    link_opening_block = "<div class='add_option'>"
    option_label = "<label>#{t('options')}</label>"
    option_help = "<p class='help'>#{t('option_weight_help')}</p>"
    option_field_left_opening = "<div class='option_left'>"
    option_field_right_opening = "<div class='option_right' id='option_right'>"
    option_field_opening = "<div class='option_field'>"
    input_text_field = "<div class='input_text_field2'>"
    settings_label = ""
    closing_block =  "</div>"
    id = params['id']
    field = ""
    cnt = 0
    hidden_field = hidden_field_tag("field_id","#{id}")
    field_type = params[id]['field_type']
    desc_text = params[id]['description'].present? ? params[id]['description'] : ''
    desc_block =  text_area_tag("description_#{params['id']}",desc_text).html_safe
    mandatory = (params[id]['mandatory'].present? and params[id]['mandatory'] == 'true') ? true : false
    mandatory_block = check_box_tag("mandatory_#{params['id']}",'',mandatory) + mandatory_text_label
    case field_type
    when 'hr'
      field_block = t('settings_na')
      field = opening_field_block + label_opening_block + field_block + closing_block + closing_block
    when 'text'
      field_block = text_field_tag("main_label",params[id]['label']).html_safe
      field  = opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block
    when 'textarea'
      field_block = text_field_tag("main_label",params[id]['label']).html_safe

      field  = opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block
    when 'radio'
      new_option = "<div id='new_option_#{id}' class='new_option' attr_type='radio'></div>"
      field_block = text_field_tag("main_label",params[id]['label']).html_safe
      field  = new_option

      field += opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block


      params[id]['options'].each do |k,v|
        if cnt == 0
          field += option_field_left_opening + opening_field_block 
          field += label_opening_block + option_label + option_help + closing_block
          field += closing_block + closing_block
          field += option_field_right_opening
        end
        delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt}'>"
        name = "option_#{id}_#{k.downcase.gsub(' ','_')}"
        field_weight_block = text_field_tag("weight_#{name}",v['weight'].present? ? v['weight'] : '',:attr_no => cnt, :attr_type => field_type, :placeholder => t('weight')).html_safe
        field_block = text_field_tag(name,v['value'],:placeholder => t('option'),:attr_no => cnt, :attr_type => field_type).html_safe
        field += option_field_opening 
        field += option_field_opening_block + field_block + closing_block
        field += option_weight_opening_block + field_weight_block + closing_block
        field += delete_link_block_opening + closing_block + closing_block
        cnt = cnt.next
      end
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>id,:field_type=>field_type},:success => "add_new_option();",:html =>{:class => "themed_text"})
      field += new_option 
      field += option_field_opening_block + link_opening_block + add_link_block + closing_block
      field += closing_block
    when 'checkbox'
      new_option = "<div id='new_option_#{id}' class='new_option' attr_type='checkbox'></div>"
      field_block = text_field_tag("main_label",params[id]['label']).html_safe
      field  = new_option

      field += opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block
      
      params[id]['options'].each do |k,v|
        if cnt == 0
          field += option_field_left_opening + opening_field_block + label_opening_block +
            option_label + option_help + closing_block + closing_block + closing_block +
            option_field_right_opening
        end
        delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt}'>"
        name = "option_#{id}_#{k.downcase.gsub(' ','_')}"
        field_weight_block = text_field_tag("weight_#{name}",v['weight'].present? ? v['weight'] : '',:attr_no => cnt, :attr_type => field_type, :placeholder => t('weight')).html_safe
        field_block = text_field_tag(name,v['value'],:placeholder => t('option'),:attr_no => cnt, :attr_type => field_type).html_safe
        field += option_field_opening 
        field += option_field_opening_block + field_block + closing_block
        field += option_weight_opening_block + field_weight_block + closing_block
        field += delete_link_block_opening + closing_block + closing_block
        cnt = cnt.next
      end
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>id,:field_type=>field_type},:success => "add_new_option();",:html =>{:class => "themed_text"})
      field += option_field_opening_block 
      field += link_opening_block + add_link_block + closing_block + closing_block
    when 'select'
      new_option = "<div id='new_option_#{id}' class='new_option' attr_type='select'></div>"
      field_block = text_field_tag("main_label",params[id]['label']).html_safe
      field  = new_option

      field += opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block
      lp = params[id]['options']
      lp.each do |k,v|
        if cnt == 0
          field += option_field_left_opening 
          field += opening_field_block + label_opening_block + option_label + option_help + closing_block
          field += closing_block + closing_block
          field += option_field_right_opening
        end
        delete_link_block_opening = "<div class='delete_option' attr_no='#{cnt}'>"
        name = "option_#{id}_#{k.downcase.gsub(' ','_')}"

        wv = (action_type == 'update') ? v['weight'] : ''
        name_value = (action_type == 'update') ? v['value'] : "#{t('option')} #{cnt+1}"
        field_weight_block = text_field_tag("weight_#{name}}",wv,:attr_no => cnt, :attr_type => field_type, :placeholder => t('weight')).html_safe
        field_block = text_field_tag(name,name_value,:placeholder => t('option'),:attr_no => cnt, :attr_type => field_type).html_safe
        field += option_field_opening 
        field += option_field_opening_block + field_block + closing_block
        field += option_weight_opening_block + field_weight_block + closing_block
        field += delete_link_block_opening + closing_block + closing_block
        cnt = cnt.next
      end
      add_link_block = link_to_remote('Add option',:url => {:action => :add_option,:cnt=>cnt,:ts=>id,:field_type=>field_type},:success => "add_new_option();",:html =>{:class => "themed_text"})
      field += option_field_opening_block + link_opening_block + add_link_block + closing_block
      field += closing_block
      
    when 'file'
      field_block = text_field_tag("main_label",params[id]['label']).html_safe
      field  = opening_field_block

      field += opening_field_block + label_opening_block + mandatory_label + closing_block
      field += input_text_field + mandatory_block + closing_block + closing_block
      field += opening_field_block + label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block + closing_block
      field += opening_field_block2 + label_opening_block + desc_label + closing_block
      field += field_opening_block + desc_block + closing_block + closing_block
    end
    return hidden_field + opening_setting_block + field + closing_block
  end
  
  def make_field obj ## makes new field
    ts = Time.now.to_i
    opening_field_block = "<div attr_life='new' id='field_block_#{ts}' class='field_block' attr-type='"+obj.field_type+"'>"
    closing_block =  "</div>"
    delete_field = "<div class='delete_field' attr_message='#{t('confirm_delete')}'></div"
    cnt = 0
    case obj.field_type
    when 'text' ## text field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("text_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = text_field_tag("form_template[text][#{ts}]").html_safe
      field  = label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'textarea' ## textarea field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("textarea_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = text_area_tag("textarea_#{ts}").html_safe
      field  = label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'file' ## file field block
      label_opening_block = "<div class='label_text_field'>"
      label_block = label_tag("file_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      field_opening_block = "<div class='input_text_field'>"
      field_block = file_field_tag("file_#{ts}").html_safe
      field  = label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'radio' ## radio field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("checkbox_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      2.times{obj.form_field_options.build}
      option_block = ""
      obj.form_field_options.each do |field_option|
        cnt = cnt.next
        option_block += field_opening_block
        option_block += radio_button_tag("option_#{ts}","Option #{cnt}",false,:attr_life=>'new').html_safe
        option_block += label_tag("option_#{ts}","Option #{cnt}").html_safe
        option_block += closing_block
      end
      field  = label_opening_block + label_block + closing_block
      field += option_block
    when 'checkbox' ## checkbox field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("checkbox_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      2.times{obj.form_field_options.build}
      option_block = ""
      obj.form_field_options.each do |field_option|
        cnt = cnt.next
        option_block += field_opening_block
        option_block += check_box_tag("option_#{ts}","Option #{cnt}",false,:attr_life=>'new').html_safe
        option_block += label_tag("option_#{ts}","Option #{cnt}").html_safe
        option_block += closing_block
      end
      field  = label_opening_block + label_block + closing_block
      field += option_block
    when 'select' ## select field block
      label_opening_block = "<div class='label_text_field'>"
      field_opening_block = "<div class='input_text_field'>"
      label_block = label_tag("select_#{ts}", t("#{obj.label}"),:class => 'main_label').html_safe
      2.times{obj.form_field_options.build}
      option_block = []
      obj.form_field_options.each do |field_option|
        cnt = cnt.next
        option_block.push "Option #{cnt}"
      end
      field_block = select_tag("select_#{ts}",options_for_select(option_block,0)).html_safe
      field  = label_opening_block + label_block + closing_block
      field += field_opening_block + field_block + closing_block
    when 'hr'
      field_opening_block = "<div class='horizontal_break'>"
      field_block = '<hr/>'
      field = field_opening_block + field_block + closing_block
    end
    return opening_field_block + field + delete_field + closing_block
  end
  
end


