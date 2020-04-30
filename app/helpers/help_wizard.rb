module HelpWizard

  # school_ids, school_date, start_date, end_date, for a config_name
  @@configurations = {}

  # use it to render a wizard from any page. by default will render a partial 'help_wizard/_controllername_action_name'
  # or pass those as options :controller_name, :action_name.
  # or pass a partial,  'partial' will look for template 'help_wizard/_partial'
  # option :help_config will use the configuration values for the given config name
  def render_help_wizard (options={})
    controller_name = options[:controller_name] || controller.controller_name
    action_name = options[:action_name] || controller.action_name
    help_config = options[:help_config]

    @_allowed_sections = []

    help_name = "#{controller_name}_#{action_name}"
    partial_file = "help_wizard/#{options[:partial] || help_name}"
    @hide_help = !show_help?


    help_content =  help_enabled?(help_config) ? (render :partial=> partial_file) : ''
    return help_content if @_allowed_sections.empty? || (@_allowed_sections.uniq.include? true)
  end

  # makes a help_wizard component. type comes as
  def help_wizard(type, description) # type can be Update or New, description about the help
    wizard_action = @hide_help ? 'Show more' : 'Hide'
    wizard_class = 'wizard'
    wizard_class += ' is_collapsed' if @hide_help

    content_tag_concat :div, :class=>wizard_class, :dir=>'ltr' do
      content_tag_concat :div, :class=>'wizard_bar' do
        content_tag_concat :div, type, :class=>"wizard_bar__info#{' is_guide' if type=='Guide'}"
        content_tag_concat :p, description, :class=>'wizard_bar__text'
        content_tag_concat :p, wizard_action, :class=>'wizard_bar__action'
      end

      content_tag_concat :div, :class=>'wizard_content' do
        yield if block_given?
      end
    end

  end

  def help_section (opts = {}, &block)
    allowed = opts.blank? ? true : ( permitted_to? opts[:action], opts[:controller] )
    @_allowed_sections << allowed
    yield block if block_given? && allowed
  end

  private

  def content_tag_concat (*args, &block)
    concat(content_tag *args, &block)
  end

  def show_help?
    return make_cookie if cookies[:help_wizard].nil?
    cookies[:help_wizard] == '0' ? false : true
  end

  def make_cookie
      cookies[:help_wizard] = {
          :value => 1,
          # :expires => 1.month.from_now,
          :path => request.path
      }
      return true
  end

  def help_enabled? (help_config)
    config = @@configurations[help_config]
    return true if help_config.nil? || config.nil?

    (config[:school_ids].nil? ?  true : (Array(config[:school_ids]).include? MultiSchool.current_school.id)) &&
    (config[:school_date].nil? ? true : (MultiSchool.current_school.created_at >= config[:school_date].beginning_of_day)) &&
    (config[:start_date].nil? ? true : (Date.today >= config[:start_date])) &&
    (config[:end_date].nil? ? true : (Date.today < config[:end_date]))
  end

end