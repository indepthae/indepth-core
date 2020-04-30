class ImportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def new
    @export = Export.find(params[:id])
    @import = @export.imports.build
    instructions
  end
   
  if Rails.env.production? || Rails.env.development?
    rescue_from FasterCSV::MalformedCSVError do |exception|
      @import.errors.add_to_base "Wrong file format.Please select a CSV file only to upload"
      unless @update
        respond_to do |format|
          format.html { render :new }
        end
      else
        respond_to do |format|
          format.html { render :edit }
        end
      end
    end
  end

  def create
    @export = Export.find(params[:import][:export_id])
    @import = @export.imports.build(params[:import]) 
    @update = false
    instructions
    if params[:csv_file].present? 
      read_file = FasterCSV.read(params[:csv_file].path)
      #r = %x{wc -l "#{params[:csv_file].path}"}.to_i
      if read_file.size > 1
        if read_file.size <= 1001
          @import.csv_save(params[:csv_file])
          @import.reload
          paperclip_var = @import.instance_variable_get :@_paperclip_attachments
          paperclip_var.delete :csv_file      
          (1...read_file.size).step(200).each do |line_number|
            @import.job_count += 1
            @import.job_type = "1"
            @import.extraction_number = line_number
            Delayed::Job.enqueue(@import,{:queue => 'custom_import'})
          end
          @import.save
          flash[:notice] = "Data import in queue for export <b>#{@export.name}</b>. <a href='/scheduled_jobs/Import/1'>Click Here</a> to view the scheduled job."
          redirect_to imports_path(:export_id => @export.id)
        else
          flash[:error] = "Too large CSV file.Maximum 1000 rows can be present."
          redirect_to new_import_path(:id => @export.id)
        end
      else
        flash[:error] = t('no_data_found')
        redirect_to new_import_path(:id => @export.id) 
      end
    else
      flash[:error] = t('no_file_uploaded')
      redirect_to new_import_path(:id => @export.id) 
    end      
  end

  def instructions
    settings = @import.load_yaml
    injectable_columns = []
    @guardian_temp = []
    @guardian_columns = []
    @additional_fields = {}
    @values = {}
    @mandatory = {}
    @temp = {}
    @additional_detail = []
    @bank_detail = []
    @privilege = []
    @tags = []
    @model = @export.model
    main_columns = Export.place_overrides(@model) 
    compalsary_columns = Export.compulsory_associates_columns(@model)
    if settings[@model.underscore]["inject"].present? 
      injectable_columns = settings[@model.underscore]["inject"].map{ |injectable_column| "*#{injectable_column.to_s.humanize}|inject" }
    end
    @main_columns = injectable_columns+ main_columns + compalsary_columns
    unless settings[@model.to_s.underscore]["instructions"].nil?
      @temp = settings[@model.to_s.underscore]["instructions"].select{ |key, value| value } 
    end 
    if @model == "Student"
      unless settings["guardian"]["instructions"].nil? 
        @guardian_columns = Export.place_overrides("Guardian")
        @guardian_columns.delete("*Ward Admission Number|Guardian")
        @guardian_temp = settings["guardian"]["instructions"].select{ |key, value| value }
      end
    end
    @associated_column = @export.associated_columns
    @associated_column.each do |a|
      if (a.split('|').second == "#{@model.downcase}_additional_detail" || a.split('|').second == "#{@model.underscore.split('_').first}_additional_detail")
        @additional_detail << a
      elsif a.split('|').second == "employee_bank_detail"
        @bank_detail << a
      elsif a.split('|').second == "privileges"
        @privilege << a
      elsif a.split('|').second == "tags"
        @tags << a
      end
    end
    @additional_detail.each_with_index do |a,index|
      if @model == "Student" || @model == "Book" || @model == "Hostel" || @model == "RoomDetail" || (@model == "Employee" && a.split('|').second == "#{@model.downcase}_additional_detail")   
        @additional_fields[index] = settings[@model.to_s.underscore]["additional_join"].to_s.constantize.find_by_name(a.split('|').first)  
        @values[index] = @additional_fields[index].send(settings[@model.to_s.underscore]["options_join"].to_s)
        @mandatory[index] = @additional_fields[index].is_mandatory      
      end
    end 
  end
  
  def index
    @export = Export.find(params[:export_id])
    @imports = @export.imports.all.paginate :per_page => 20, :page => params[:page], :order => 'created_at DESC'
  end

  def edit
    @export = Export.find(params[:id])
    @models = Export.get_models.select{ |model| defined?model.second.camelize.constantize == "constant" }
    @settings = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_custom_import/config", "instruction_for_edit.yml")) if File.exists?("#{Rails.root}/vendor/plugins/fedena_custom_import/config/instruction_for_edit.yml")
  end

  def create_import_for_edit
    @export = Export.find(params[:import][:export_id])
    @models = Export.get_models.select{ |model| defined?model.second.camelize.constantize == "constant" }
    @settings = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_custom_import/config", "instruction_for_edit.yml")) if File.exists?("#{Rails.root}/vendor/plugins/fedena_custom_import/config/instruction_for_edit.yml")
    @import = @export.imports.editable_imports.build(params[:import])
    @update = true
    if params[:csv_file].present?
      read_file = FasterCSV.read(params[:csv_file].path)
      if read_file.size > 1
        if read_file.size <= 1001
          @import.csv_save(params[:csv_file])
          @import.reload
          paperclip_var = @import.instance_variable_get :@_paperclip_attachments
          paperclip_var.delete :csv_file
          (1...read_file.size).step(200).each do |line_number|
            @import.job_count += 1
            @import.job_type = "1"
            @import.extraction_number = line_number
            Delayed::Job.enqueue(@import,{:queue => 'custom_import'})
          end
          @import.save
          flash[:notice] = "Data import in queue for export <b>#{@export.name}</b>. <a href='/scheduled_jobs/Import/1'>Click Here</a> to view the scheduled job."
          redirect_to imports_path(:export_id => @export.id)
        else
          flash[:error] = "Too large CSV file.Maximum 1000 rows can be present."
          redirect_to edit_import_path(:id => @export.id)
        end
      else
        flash[:error] = t('no_data_found')
        redirect_to edit_import_path(:id => @export.id) 
      end
    else
      flash[:error] = t('no_file_uploaded')
      redirect_to edit_import_path(:id => @export.id)
    end 
  end

  def filter
    @export = Export.find(params[:export_id])
    filter_param = params[:filter_imports]
    @imports = if filter_param == "all"
      @export.imports.all.paginate :per_page => 20, :page => params[:imports_page]
    elsif filter_param == "failed"
      @export.imports.find(:all, :conditions => {:status => ["failed", t('imports.failed')]}).paginate :per_page => 20, :page => params[:imports_page]
    elsif filter_param == "completed"
      @export.imports.find(:all, :conditions => {:status => ["completed_with_errors", t('imports.completed_with_errors')]}).paginate :per_page => 20, :page => params[:imports_page]
    elsif filter_param == "success"
      @export.imports.find(:all, :conditions => {:status => ["success", t('imports.success')]}).paginate :per_page => 20, :page => params[:imports_page]
    else
      []
    end
    render :update do |page|
      page.replace_html "list_imports", :partial => "list_imports"
    end
  end
end
