class DataExportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @data_exports = DataExport.paginate(:order => "id DESC",:page => params[:page],:per_page => 30)
    
    respond_to do |format|
      format.html
    end
  end
  
  def new
    @export_structures = ExportStructure.all(:order => "model_name ASC", :conditions => "model_name <> 'vehicle'")
    @export_structures.reject!{|de| (FedenaPlugin.accessible_plugins.include? de.plugin_name) == false unless de.plugin_name.nil?}
    @export_structures.reject!{|de| Date.today - 30.days < de.data_export.created_at.to_date if de.data_export.present?}
    @data_export = DataExport.new
    @models = params[:models]
    @file_format = params[:file_format]
    respond_to do |format|
      format.html #new.html.erb
    end
  end

  def create
    @data_export = DataExport.new(params[:data_export])
    if params[:data_export][:file_format].present?
      @models = params[:model_ids].select{|key,value| value == "1"}.map(&:first)
      if @models.present?
        @models.each do |model_id|
          export_structure = ExportStructure.find_by_id(model_id)
          @new_data_export = DataExport.new(:export_structure_id => export_structure.id,:file_format => params[:data_export][:file_format],:status => "In progress")
          @new_data_export.job_type = "1"
          Delayed::Job.enqueue(@new_data_export)
        end
        flash[:notice]="Data export in queue </b>. <a href='/scheduled_jobs/DataExport/1'>Click Here</a> to view the scheduled jobs."
        redirect_to data_exports_path
      else
        flash[:notice] = "Please select an export to continue."
        redirect_to new_data_export_path(:models => @models,:file_format => params[:data_export][:file_format])
      end
    else
      @models = params[:model_ids].select{|key,value| value == "1"}.map(&:first)
      unless @models.blank?
        @export_structures = ExportStructure.all(:order => "model_name ASC")
        @export_structures.reject!{|de| (FedenaPlugin.accessible_plugins.include? de.plugin_name) == false unless de.plugin_name.nil?}
        @export_structures.reject!{|de| Date.today - 30.days < de.data_export.created_at.to_date if de.data_export.present?}
        @data_export.valid?
        render :new
      else
        flash[:notice] = "Please select an export to continue."
        redirect_to new_data_export_path(:models => @models,:file_format => params[:data_export][:file_format])
      end
    end
  end

  def download_export_file
    @data_export = DataExport.find(params[:id])
    send_file(@data_export.export_file.path)
  end

end
