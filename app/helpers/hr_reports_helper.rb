module HrReportsHelper
  def render_input_fields
    input_content = ""
    @input_fields.each_with_index do |input_field, i|
      if input_field.is_a? Array
        field_names = input_field.collect(&:name)
        input_content += content_tag :div, :class => 'pair_div' do
          input_cont = ""
          input_field.each_with_index do |field, index|
            remaining_elements = field_names.reject{|e| e == field.name}
            opts = {:section => 'input_values'}
            opts[:select_options] = {:class => "select-list", :id => field.name + '_list', :name => 'input_values[' + field.name + ']', :dependent_field => field.dependent_field, :field => field.name, :prompt_message => 'select_' + field.name, :child => field.child, :onchange => "reset_fields('#{remaining_elements.join(",")}');", :pair => "pair_#{i}"}
            input_cont += or_content unless index == 0
            input_cont += container_content(field, opts)
          end
          input_cont
        end
      else
        opts = {:section => 'input_values'}
        opts[:select_options] = {:class => 'select-list', :id => input_field.name + '_list', :name => 'input_values[' + input_field.name + ']', :dependent_field => input_field.dependent_field, :field => input_field.name, :prompt_message => 'select_' + input_field.name, :child => input_field.child}
        input_content += container_content(input_field, opts)
      end
    end
    input_content
  end

  def render_filter_fields
    filter_content = ""
    @filters.each do |filter|
      opts = {:section => 'filter_values'}
      opts[:select_options] = {:class => 'select-list', :id => filter.name + '_filter_list', :name => 'filter_values[' + filter.name + ']', :field => filter.name, :prompt_message => 'select_' + filter.name}
      filter_content += filter_content(filter, opts)
    end
    filter_content
  end

  def render_template_fields
    template_content = ""
    @templates.each do |template|
      opts = {:section => 'template_values'}
      opts[:select_options] = {:class => 'select-list', :id => template.name + '_template_list', :name => 'template_values[' + template.name + ']', :field => template.name, :prompt_message => 'select_' + template.name}
      template_content += template_content(template, opts)
    end
    template_content
  end

  private

  def content_tag_concat (*args, &block)
    concat(content_tag *args, &block)
  end

  def container_content(field, opts={})
    unless field.field_type == "date_range"
      label_field_pair opts do
        label_field(field.name, field.name + "_text")
        text_div_field opts do
          temp = case field.field_type
          when "select"
            select_field(field.value, opts)
          when "multi_select"
            opts[:select_options][:multiple] = true if opts[:select_options].present?
            select_field(field.value, opts)
          end
          temp += opts[:select_options][:child]  ? image_content : ""
        end
      end
    else
      date_range_content(field, opts)
    end
  end

  def filter_content(field, opts={})
    label_field_pair opts do
      label_field(field.name, field.name + "_text")
      text_div_field opts do
        case field.field_type
        when "select"
          select_field(field.value, opts)
        when "multi_select"
          opts[:select_options][:multiple] = true if opts[:select_options].present?
          select_field(field.value, opts)
        end
      end
    end
  end

  def template_content(field, opts={})
    label_field_pair opts do
      label_field(field.name, field.name + "_text")
      choose_while_generating(field, opts.clone)
      opts[:select_options][:disabled] = true
      text_div_field opts do
        case field.field_type
        when "select"
          select_field(field.value, opts)
        when "multi_select"
          opts[:select_options][:multiple] = true if opts[:select_options].present?
          select_field(field.value, opts)
        end
      end
    end
  end

  def label_field_pair(opts = {}, &block)
    content_tag :div, :class => opts[:class]||'label-field-pair', :id => opts[:field_div_id], &block
  end

  def label_field(name, value)
    content_tag_concat :label, t(value), :for => name
  end

  def label_content(name, value)
    content_tag :label, t(value), :for => name
  end

  def text_div_field(opts = {}, &block)
    content_tag_concat :div, :class => 'text-input-bg '+opts[:text_div_class].to_s, :id => opts[:text_div_id], &block
  end

  def image_content
    image_tag("loader.gif", :align => "absmiddle", :border => 0, :id => "loader", :style =>"display: none;")
  end
  
  def select_field(field_value, opts={})
    content_tag_concat :select, opts[:select_options] do
      field_value.unshift([t(opts[:select_options][:prompt_message]), ""]) if opts[:select_options].present? and opts[:select_options][:prompt_message].present? and !opts[:select_options][:multiple]
      if field_value.is_a? Hash
        grouped_options_for_select(field_value)
      else
        options_for_select(field_value)
      end
    end
  end

  def date_range_content(field, opts={})
    options = opts[:select_options].merge({:year_range => 15.years.ago..5.years.from_now, :readonly=>true, :popup=>"force"})
    options.delete(:name)
    date_content = label_field_pair :class => "label-field-pair date-field" do
      label_field('start_date', 'start_date')
      text_div_field opts do
        calendar_date_select_tag opts[:section]+'[start_date]', I18n.l(field.value.first,:format=>:default), options
      end
    end
    date_content += label_field_pair :class => "label-field-pair date-field" do
      label_field('end_date', 'end_date')
      text_div_field opts do
        calendar_date_select_tag opts[:section]+'[end_date]', I18n.l(field.value.last,:format=>:default), options
      end
    end
    date_content
  end

  def choose_while_generating(template, opts)

    opts[:text_div_class] = 'choose_value'
    text_div_field opts do
      content = radio_button(template.name.to_s, "choose", "all", :checked => true, :onchange => "change_template_value(this);", :field => template.name.to_s)
      content += label_content(template.name.to_s + '_choose_all', 'all')
      content += radio_button(template.name.to_s, "choose", "specific", :onchange => "change_template_value(this);", :field => template.name.to_s)
      content += label_content(template.name.to_s + '_choose_specific', 'specific')
    end

  end

  def or_content
    content_tag :div, t('or').upcase, :class => 'or_section'
  end

  def date_display(date)
    range = date.split(",")
    diff = (range.last.to_date - range.first.to_date).to_i
    if diff == 0
      format_date(range.first)
    elsif (diff > 16)
      format_date(range.first,:format => :month_year)
    else
      format_date(range.first) + " - " + format_date(range.last)
    end
  end
end
