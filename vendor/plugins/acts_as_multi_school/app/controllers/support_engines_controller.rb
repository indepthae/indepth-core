class SupportEnginesController < MultiSchoolController
  filter_access_to :all
  before_filter :set_details
  
  def task_list
    @available_script_details = @available_scripts.map{|sc| [sc.name, sc.description]}
  end
  
  def task_details
    @column_map = "| "
    @current_script.instruction.sort_by {|_key, value| value}.each{|s| @column_map += "(#{s[1]}) #{s[0]} | "}
    csv_check = @current_script.params_list.values.include?"file"
    @info_name = csv_check ? "CSV Header Mapping" : "Instructions"
  end
  
  def view_log
    @task_log = SupportTaskStat.find_by_id(params[:id])
    if @task_log.log.present? and File.exists?("#{Rails.root}/#{@task_log.log}")
      @logs = `cat #{@task_log.log}`
    else
      @logs = "Log file does not exists!!!"
    end
  end
  
  def task_status
    if params[:script].present?
      @all_status = SupportTaskStat.find(:all, :conditions=>{:owner_id=>params[:id], :script_id=>params[:script]}).paginate(:order=>"id DESC", :page => params[:page], :per_page=>10)
    else  
      @all_status = SupportTaskStat.find(:all, :conditions=>{:owner_id=>params[:id]}).paginate(:order=>"id DESC", :page => params[:page], :per_page=>10)
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @all_status }
    end
  end
  
  def run_task
    params_hash = params[:task].present? ? params[:task] : Hash.new
    #params_hash['csv_file'] = params[:uploaded_file].path if params[:uploaded_file].present?
    ########
    if params[:uploaded_file].present?
      csv_file_path = params[:uploaded_file].path
      system("rsync #{csv_file_path} #{Rails.root}/log/support_task")
      csv_file_path = csv_file_path.gsub!('/tmp','')
      file_path = "#{RAILS_ROOT}/log/support_task#{csv_file_path}"
      params_hash['csv_file'] = file_path
    end
    #########
    validate_details = @current_script.resolve_params(params_hash)
    if validate_details
      sts  = SupportTaskStat.create(:owner_id=>params[:id], :script_id=>params[:script], :task_type=>params[:commit], :params=>params_hash)
      msg = "Sucessfully validated and moved to delayed job. Please check #{link_to 'status', task_status_support_engines_path(:id=>params[:id], :script=>params[:script])} for move info"
    else
      msg = "Validation error!!"
    end
    respond_to do |format|
      flash[:notice] = msg
      format.html { redirect_to :action => "task_details", :id=>params[:id], :script=>params[:script] }
    end
  end
  
  private
  
  def set_details
    @available_scripts = SupportTaskEngine.scripts
    @current_script = params[:script].present? ? @available_scripts[params[:script].to_i] : []
  end
  
end
