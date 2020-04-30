#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
require 'date_format'
module ApplicationHelper
  include RemarksHelper
  include DateFormater
  include HelpWizard

  def show_header_icon
    controller_name = controller.controller_path
    "<div class='header-icon #{controller_name}-icon'></div>".html_safe
  end

  def make_breadcrumb
    target_controller = controller.controller_path
    target_action = controller.action_name
    crumb_key = "#{target_controller.to_s}_#{target_action.to_s}"
    breadcrumb crumb_key.to_sym
  end

  def render_breadcrumbs
    breadcrumb :separator => '<div class = "bread-crumb-separator"> > </div>'.html_safe,:autoroot => true,:show_root_alone => false,:link_last => false
  end

  def get_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    if controller.controller_path == 'user' and controller.action_name == 'dashboard'
      stylesheets << @direction+'_layouts/dashboard'
    elsif controller.controller_path == 'user' and controller.action_name == 'set_new_password'
      stylesheets << @direction+"_layouts/login"
    else
      stylesheets << @direction+'application'
      stylesheets << @direction+'popup.css'
    end
    stylesheets << @direction+'_styles/ui.all.css'
    stylesheets << @direction+'modalbox'
    stylesheets << @direction+'autosuggest-menu.css'
    stylesheets << @direction+'calendar'
    ["#{@direction}#{controller.controller_path}/#{controller.action_name}"].each do |ss|
      stylesheets << ss
    end
    plugin_css_overrides = FedenaPlugin::CSS_OVERRIDES["#{controller.controller_path}_#{controller.action_name}"]
    stylesheets << plugin_css_overrides.collect{|p| "#{@direction}plugin_css/#{p}"}
    FedenaPlugin::ADDITIONAL_LINKS[:icon_class_link].each do |mod|
      if FedenaPlugin.can_access_plugin?(mod[:plugin_name].to_s)
        stylesheets << @direction+(mod[:stylesheet_path].to_s)
      end
    end
    return stylesheets
  end

  def get_forgotpw_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    stylesheets << @direction+"_layouts/forgotpw"
    stylesheets << @direction+"_styles/style"
  end

  def get_pdf_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    ["#{@direction}#{controller.controller_path}/#{controller.action_name}"].each do |ss|
      stylesheets << ss
    end
    plugin_css_overrides = FedenaPlugin::CSS_OVERRIDES["#{controller.controller_path}_#{controller.action_name}"]
    stylesheets << plugin_css_overrides.collect{|p| "#{@direction}plugin_css/#{p}"}
  end

  def observe_fields(fields, options)
	  with = ""                          #prepare a value of the :with parameter
	  for field in fields
		  with += "'"
		  with += "&" if field != fields.first
		  with += field + "='+escape($('" + field + "').value)"
		  with += " + " if field != fields.last
	  end

	  ret = "";      #generate a call of the observer_field helper for each field
	  for field in fields
		  ret += observe_field(field,	options.merge( { :with => with }))
	  end
	  ret
  end

  def shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = shortened.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def currency_with_amount
    "#{t('amount')} (#{currency})"
  end

   def validate_edit_sms_template
      SmsSetting.find_by_settings_key("ApplicationEnabled")
   end
  ## def  to set line in reports if value not present


  #  def currency
  #    Configuration.find_by_config_key("CurrencyType").config_value
  #  end

  def pdf_image_tag(image, options = {})
    options[:src] = File.expand_path(RAILS_ROOT) + "/public/images"+ image
    tag(:img, options)
  end

  def available_language_options
    options = []
    AVAILABLE_LANGUAGES.each do |locale, language|
      options << [language, locale]
    end
    options
  end

  def financial_year_options
    options = []
    options << [t('financial_years.default_financial_year'), 0]
    @financial_years.each do |fy|
      options << [fy.name, fy.id]
    end
    options
  end

  def current_financial_year
    session[:financial_year] || FinancialYear.active.try(:last)
  end

  def rtl?
    if session[:language].nil?
      lan = Configuration.find_by_config_key("Locale").config_value
      lan = "en" unless lan.present?
    else
      lan=session[:language]
    end
    if controller and is_cce_controller?
      return false
    else
      @rtl ||= RTL_LANGUAGES.include? lan.to_sym
    end
  end
  
  def is_cce_controller?
    controller.controller_path == 'cce_reports' or controller.controller_path == 'icse_reports' or controller.controller_path == 'asl_scores' or controller.controller_path == 'ia_scores'
  end

  def main_menu
    Rails.cache.fetch("user_main_menu#{session[:user_id]}"){
      render :partial=>'layouts/main_menu'
    }
  end

  def current_school_detail
    SchoolDetail.first||SchoolDetail.new
  end

  def current_school_name
    h Rails.cache.fetch("current_school_name/#{request.host_with_port}"){
      Configuration.get_config_value('InstitutionName')
    }
  end

  def generic_hook(cntrl,act)
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].flatten.compact.each do |mod|
      if cntrl.to_s == mod[:source][:controller].to_s && act.to_s == mod[:source][:action].to_s
        if can_access_request? mod[:destination][:action].to_sym,mod[:destination][:controller].to_sym
          return link_to(mod[:title], :controller=>mod[:destination][:controller].to_sym,:action=>mod[:destination][:action].to_sym)
        end
      end
    end
    return ""
  end

  def generic_dashboard_hook(cntrl,act)
    dashboard_links = ""
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].compact.flatten.each do |mod|
      if cntrl.to_s == mod[:source][:controller].to_s && act.to_s == mod[:source][:action].to_s
        if can_access_request? mod[:destination][:action].to_sym,mod[:destination][:controller].to_sym

          dashboard_links += <<-END_HTML
             <div class="link-box">
                <div class="link-heading">#{link_to t(mod[:title]), :controller=>mod[:destination][:controller].to_sym, :action=>mod[:destination][:action].to_sym}</div>
                <div class="link-descr">#{t(mod[:description])}</div>
             </div>
          END_HTML
        end
      end
    end
    return dashboard_links
  end

  def precision_label(val)
    if defined? val and val != '' and !val.nil?
      return sprintf("%0.#{precision_count}f",val)
    else
      return
    end
  end

  def precision_count
    @precision_count ||= FedenaPrecision.get_precision_count 
  end


  def render_generic_hook
    hooks =  []    
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].compact.flatten.select{|h| h if (h[:source][:controller] == controller_name.to_s && h[:source][:action] == action_name.to_s)}.each do |hook|
      if can_access_request? hook[:destination][:action].to_sym,hook[:destination][:controller].to_sym
        hook_id = hook[:id] if hook[:id].is_a?(Proc)
        hook_active = hook[:active] if hook[:active].is_a?(Proc)
        hook[:id] = instance_eval(&hook[:id]) if hook[:id].is_a?(Proc)
        hook[:active] = instance_eval(&hook[:active]) if hook[:active].is_a?(Proc)
        h = Marshal.load(Marshal.dump(hook))
        hook[:id] = hook_id if hook_id.is_a?(Proc)
        hook[:active] = hook_active if hook_active.is_a?(Proc)
        h[:title] = t(hook[:title])
        h[:description] = t(hook[:description])
        hooks << h
      end
    end
    return hooks.to_json
  end

  def render_generic_multi_hook_js
    js = []
    FedenaPlugin::ADDITIONAL_LINKS[:generic_multi_hook].compact.flatten.select{|h| h if (h[:load_source][:controller] == controller_name.to_s && h[:load_source][:action] == action_name.to_s)}.each do |hook|
      if can_access_request? hook[:destination][:action].to_sym,hook[:destination][:controller].to_sym
        js << hook[:js]
      end
    end
    return "#{js.join(',')}"
  end

  def render_generic_multi_hook
    hooks =  []    
    FedenaPlugin::ADDITIONAL_LINKS[:generic_multi_hook].compact.flatten.select{|h| h if (h[:source][:controller] == controller_name.to_s && (h[:source][:action].include? action_name.to_s))}.each do |hook|
      if can_access_request? hook[:destination][:action].to_sym,hook[:destination][:controller].to_sym
        hook_target_id = hook[:target_ids] if hook[:target_ids].is_a?(Proc)
        hook_active = hook[:active] if hook[:active].is_a?(Proc)
        hook[:target_ids] = instance_eval(&hook[:target_ids]) if hook[:target_ids].is_a?(Proc)
        hook[:active] = instance_eval(&hook[:active]) if hook[:active].is_a?(Proc)
        h = Marshal.load(Marshal.dump(hook))
        hook[:target_ids] = hook_target_id if hook_target_id.is_a?(Proc)
        hook[:active] = hook_active if hook_active.is_a?(Proc)
        h[:title] = t(hook[:title])
        h[:description] = t(hook[:description])
        hooks << h
      end
    end
    return "render_generic_multi_hook(#{hooks.to_json})" if hooks.present?
  end

  def roll_number_enabled?
    @enabled ||= Configuration.get_config_value('EnableRollNumber') == "1" ? true : false
  end
  
  def report_job_status(method, model)
    <<-END_HTML
    <div id="inner-tab-menu">
    <ul>
      <li class="themed_bg themed-dark-hover-background"><a href='/reports/csv_reports?method=#{method}&model=#{model}' target='_blank'>#{t('scheduled_jobs')}</a></li>
    </ul>
   </div>
    END_HTML
  end

  include WillPaginate::ViewHelpers

  def will_paginate_with_i18n(collection, options = {})
    if ([:next_label,:previous_label,"next_label","previous_label"] & options.keys).blank?
      will_paginate_without_i18n(collection, options.merge(:previous_label => I18n.t(:previous_text), :next_label => I18n.t(:next_text)))
    else
      will_paginate_without_i18n(collection, options)
    end
  end
  alias_method_chain :will_paginate, :i18n

  def error_messages_for(*params)
    opts=params.extract_options!
    unless (opts.keys & [:header_message,"header_message"]).present?
      opts.merge!(:header_message=>nil)
    end
    params.push(opts)
    super
  end

  def to_grade_point(grade,grading_level_list)
    grading_level_list.to_a.select{|g| g.name == grade}.first.try(:credit_points) || ""
  end

  def session_fingerprint_field
    hidden_field_tag :session_fingerprint, session_fingerprint
  end


  def pagination_status(collection)
    unless collection.nil?
      page_number = collection.current_page
      per_page = collection.per_page
      tot_count = collection.total_entries
      page_start = (page_number - 1) * per_page + 1
      page_end = (page_start - 1 ) + per_page
      page_end = (page_end > tot_count ? tot_count : page_end)
      if per_page != tot_count && tot_count > per_page
        "<div class='pagination_status'>#{t('showing')} #{page_start} - #{page_end} out of #{tot_count}</div>"
      end
    end
  end

  def payslip_management_header_icon(finance)
    controller_name = finance ? 'finance' : 'employee'
    "<div class='header-icon #{controller_name}-icon'></div>".html_safe
  end
  
  def show_notification_icon(model)
    "<div class='notification-icon #{model.underscore}-notification-icon'></div>".html_safe
  end
  
  def notification_reference_link(link)
    if link.present?
      target = link[:target]
      target_param = link[:target_param]
      target_value = link[:target_value]
      if @current_user.parent? and !Notification::NOTIFICATION_REFERENCE_LIST[:parent].include? target
        return nil
      end
      url = case target
      when 'choose_elective'
        "/student/my_subjects/#{@current_user.student_entry.id.to_s}"
      when 'view_calendar'
        '/calendar'
      when 'view_reports'
        "/student/reports/#{@current_user.student_entry.id.to_s}"
      when 'view_fees'
        "/student/fees/#{@current_user.student_entry.id.to_s}" if @current_user.student?
      when 'view_rejected_payslip'
        "employee_payslips/view_all_rejected_payslips"
      when 'view_payslip'
        "employee_payslips/view_payslip_pdf/#{target_value}"
      when 'view_timetable'
        if(target_param == 'employee_id')
          "timetable/employee_timetable/#{@current_user.employee_record.id.to_s}"
        elsif(target_param == 'student_id')
          "timetable/student_view/#{@current_user.student_entry.id.to_s}"
        end
      when 'employee_leave'
        target = link[:link_text] || 'leave'
        "employee_attendance/leave_application/#{target_value}?from=pending_leave_applications"
      when 'open_discussion'
        "groups/#{target_value}"
      when 'view_form'
        "forms/#{target_value}"
      when 'view_placement_details'
        "placementevents/#{target_value}"
      when 'view_task'
        "tasks/#{target_value}"
      when 'view_complaint'
        "discipline_complaints/#{target_value}"
      when 'view_event'
        "alumni_events/#{target_value}"
      when 'show_news'
        "news/#{target_value}"
      when "show_gallery_album"
        "galleries/category_show/#{target_value}"
      else
        nil
      end
      if url
        link_to t("#{target}"), url
      end
    end
  end
  
  def beta_header
    "<sup>beta</sup>"
  end
  
  def array_to_li(array)
    element = "<ul>"
    array.each do |el|
      element << "<li>#{el}</li>"
    end
    element << "</ul>"
    
    element
  end
  
  def leave_reset_configuration
    Configuration.get_config_value('LeaveResetSettings') || "0"
  end
  
  def link_to_add_nested_field(name,form,association,partial)
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end

  def cache_if_memcache (cache_key)
    memcache_on = Rails.cache.is_a? ActiveSupport::Cache::MemCacheStore
    if memcache_on
      cache(cache_key) do
        yield
      end
    else
      yield
    end
  end
end
