class TcTemplatesController < ApplicationController
  before_filter :login_required
  before_filter :template_presence_required, :only=>"settings"
  before_filter :general_settings_required, :only=>"settings"
  before_filter :find_template
  filter_access_to :all
  include TcTemplateGenerateCertificatesHelper
  def settings
    @header, @footer, @student_details = TcTemplateField.get_template_settings(@current_template)
    @student_details_ids=@current_template.tc_template_field_student_details_main_field_ids
    @config_date_format,@config_date_separator = get_date_format
  end

  def current_tc_preview
    @tc_data = @current_template.get_current_preview_settings
    render :pdf => 'transfer_certificate_preview_pdf',
      :header => {:html => nil},
      :footer => {:html => nil},
      :margin=> {:top=> 10, :bottom=> 10, :left=> 10, :right=> 10},
      :zoom => 1,:layout => "tc_pdf.html",
      :show_as_html=> params[:d].present?
  end


  private

  def get_date_format
    date_format = Configuration.find_by_config_key('DateFormat').config_value
    date_separator = Configuration.find_by_config_key('DateFormatSeparator').config_value
    return date_format,date_separator
  end

  def template_presence_required
    unless TcTemplateVersion.current
      TcTemplateVersion.initialize_first_template
      TcTemplateVersion.initialize_sub_fields
    end
  end
  def general_settings_required
    unless Configuration.find_by_config_key('DateFormat')
      flash[:notice] = "#{t('no_general_settings_found')}"
      redirect_to :controller=>"tc_templates", :action=>"index"
    end
  end

  def find_template
    @current_template = TcTemplateVersion.current
  end

end
