class ObservationRemarksController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def new
    @observation=Observation.find(params[:id])
    @observation_remark = ObservationRemark.new
  end
  
  def create
    @observation_remark = ObservationRemark.new(params[:observation_remark])
    if @observation_remark.save
      @observation = Observation.find(params[:observation_remark][:observation_id])
      @observation_remarks = @observation.observation_remarks
      flash[:notice]="Remark added successfully"
    else
      @error=true
    end
  end
  
  def edit
    @observation_remark = ObservationRemark.find(params[:id])
    @observation = @observation_remark.observation
  end
  
  def update
    @observation_remark = ObservationRemark.find(params[:id])
    if @observation_remark.update_attributes(params[:observation_remark])
      @observation = Observation.find(params[:observation_remark][:observation_id])
      @observation_remarks = @observation.observation_remarks
      flash[:notice]="Remark updated successfully"
    else
      @error=true
    end
  end
  
  def destroy
    @observation_remark = ObservationRemark.find(params[:id])
    if @observation_remark.destroy
      flash[:notice]="observation remarks deleted."
    else
      flash[:notice]="Unable to delete the observation remarks, dependent data present"
    end
    @observation = Observation.find(params[:observation_id])
    @observation_remarks = @observation.observation_remarks
    render(:update) do |page|
      page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
      page.replace_html 'observation_remarks', :partial => 'observation_remarks', :object => @observation_remarks
    end
  end
  
  def co_scholastic_remark_settings
    if request.post?
      current_setting = CceReportSetting.find_by_setting_key('ObservationRemarkMode')
      current_di_count = CceReportSetting.find_by_setting_key('DICount')
      current_setting.update_attributes(:setting_value=>params[:observation_remarks][:co_scholastic_remark_mode]) if current_setting.present?
      current_di_count.update_attributes(:setting_value=>params[:observation_remarks][:di_count]) if (current_di_count.present? and params[:observation_remarks][:di_count].present?)
      current_di_count.destroy if (current_di_count.present? and params[:observation_remarks][:di_count] == "")
      CceReportSetting.create(:setting_key=>'ObservationRemarkMode',:setting_value=>params[:observation_remarks][:co_scholastic_remark_mode]) unless current_setting.present?
      CceReportSetting.create(:setting_key=>'DICount',:setting_value=>params[:observation_remarks][:di_count]) unless (current_di_count.present? or params[:observation_remarks][:di_count].nil?)
      flash[:notice] = "Remarks setting saved"
    end
    @setting  = ((setting = CceReportSetting.find_by_setting_key('ObservationRemarkMode')).present? ? setting.setting_value : CceReportSetting::FALLBACK_SETTINGS["ObservationRemarkMode"]) 
    @di_count = ((di_count = CceReportSetting.find_by_setting_key('DICount')).present? ? di_count.setting_value : CceReportSetting::FALLBACK_SETTINGS["DICount"])
  end
  
  def get_di_info
    @di_count = ((di_count = CceReportSetting.find_by_setting_key('DICount')).present? ? di_count.setting_value : CceReportSetting::FALLBACK_SETTINGS["DICount"])
    render :update do |page|
      page.replace_html 'di_counter',:text=>'' if params[:id]=="0"
      page.replace_html 'di_counter',:partial=>'di_counter' if params[:id]=="1"
    end
  end
  
end
