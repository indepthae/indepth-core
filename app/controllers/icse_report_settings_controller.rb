class IcseReportSettingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:attribute_check=>true, :load_method => lambda { current_user }
  
  def settings
    if request.post?
      IcseReportSetting.set_setting_values(params[:icse_report_setting])
      respond_to do |format|
        format.html {
          flash[:notice] = "#{t('flash_msg8')}"
          redirect_to :action => "settings"
        }
      end
    else
      @setting = IcseReportSetting.get_multiple_settings_as_hash IcseReportSetting::SETTINGS
      @student_fields=IcseReportSetting::SETTINGS_WITH_VALUES
      @student_additional_fields=StudentAdditionalField.all(:conditions=>["input_type in (?) and status = ?",["text","belongs_to"],true])
    end 
  end
  
  def get_report_header_info
    @setting = IcseReportSetting.get_multiple_settings_as_hash ["HeaderSpace"]
    render :update do |page|
      page.replace_html 'report_desc',:partial=>'report_with_header' if params[:id]=="0"
      page.replace_html 'report_desc',:partial=>'report_without_header' if params[:id]=="1"
    end
  end
  
  def get_report_signature_info
    @setting = IcseReportSetting.get_multiple_settings_as_hash ["Signature", "SignLeftText", "SignCenterText", "SignRightText"]
    render :update do |page|
      page.replace_html 'report_sign',:partial=>'report_with_signature' if params[:id]=="0"
      page.replace_html 'report_sign',:text=>'' if params[:id]=="1"
    end
  end
  
  def get_report_grading_levels_info
    @setting = IcseReportSetting.get_multiple_settings_as_hash ["GradingLevelPosition"]
    render :update do |page|
      page.replace_html 'report_grade_levels',:partial=>'report_grading_level_positions' if params[:id]=="0"
      page.replace_html 'report_grade_levels',:text=>'' if params[:id]=="1"
    end
  end
  
  def preview
    @records=IcseReportSetting.result_as_hash
    @batch=Batch.active.last(:joins=>:students)
    @grading_levels = (@batch.present? ? @batch.grading_level_list : GradingLevel.default)
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
    @student= @batch.students.last if @batch.present?
    render :pdf => "ICSE Report Preview",:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end
  
  
end
