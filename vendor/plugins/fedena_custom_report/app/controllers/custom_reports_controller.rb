class CustomReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :find_and_check_model,:only=>[:generate,:edit]
  def find_and_check_model

    @model_name = params[:id].camelize.singularize
    unless ["Student","Employee"].include? @model_name
      flash[:notice] = "#{t(@model_name.underscore)} #{t('report_cannot_be_generated')}"
      redirect_to :action=>:index
      return
    else
      @model = Kernel.const_get(@model_name)
    end
  end
  def index
    @reports=Report.find(:all,:order =>'name ASC').paginate(:page => params[:page], :per_page => 20)
  end

  def generate
    @report=Report.new
    @report.model = @model_name
    @model.extend JoinScope
    @model.extend AdditionalFieldScope
    @search_fields = @model.fields_to_search.deep_copy
    make_report_columns
    @search_fields.each do |type,columns|
      case type
      when :string
        columns.each do |col|
          ["like","begins_with","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :date
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :association
        columns.each do |col|
          case col
          when Symbol
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"in",:column_type=>type,:field_name=>col)
          when Hash
            @report.report_queries.build(:table_name => @model_name,:column_name=>col.keys.first,:criteria=>"in",:column_type=>type,:field_name=>col.keys.first)
          end
        end
      when :boolean
        columns.each do |col|
          @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"is",:column_type=>type,:field_name=>col)
        end
      when :integer
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      end

    end
    @search_fields[:additional]= @model.additional_field_methods
    @search_fields[:bank]= @model.bank_field_methods if @report.model == "Employee"
    @model.get_additional_fields.each do |f|
      if f.name.to_i == 0
        ["equals"].each do |criteria|
          @report.report_queries.build(:table_name => @model.additional_detail_model.to_s,:column_name=>f.id,:criteria=>criteria,:column_type=>:additional,:field_name=>( f.name.downcase.gsub(" ","_") + "_additional_fields_" + f.id.to_s))
        end
      end
    end
    if @report.model == "Employee"
      @model.get_bank_fields.each do |f|
        if f.name.to_i == 0
          ["equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model.bank_detail_model.to_s,:column_name=>f.id,:criteria=>criteria,:column_type=>:bank,:field_name=>( f.name.downcase.gsub(" ","_") + "_bank_fields_" + f.id.to_s))
          end
        end
      end
    end
    @assoc_value = @report.report_queries.select{|rq| rq.column_type == :association}.inject({}){|hash,r| hash.merge(r.column_name.to_s => r.values_for_associations.map{|a| {"label" => a.to_s,"id" => a.id}})}
    if request.post?
      @report = Report.new(params[:report])
      if @report.save
        flash[:notice]="#{t('report_created_successfully')}"
        redirect_to :action => "index"
      else
        render :action => "generate"
      end
    end

  end

  def edit
    @report=Report.find params[:id]
    @model_name=@report.model
    @all_columns=@model.fields_to_search
  end

  def show
    @report=Report.find params[:id]
    @report_columns = @report.report_columns
    @report_columns.delete_if{|rc| (rc.association_method.nil? or rc.association_method.blank?) and !((@report.model_object.instance_methods+@report.model_object.column_names).include?(rc.method))}
    @report_columns.delete_if{|rc| rc.association_method.present? and @report.model_object.instance_methods.include? rc.association_method and !((rc.association_method_object.instance_methods+rc.association_method_object.column_names).include?(rc.method))}
    @column_type = Hash.new
    @report.model_object.columns_hash.each{|key,val| @column_type[key]=val.type }
    search = @report.model_object.report_search(@report.search_param)
    table_name = Kernel.const_get(@report.model.to_sym).table_name
    query_parameters = {:include=>@report.include_param,:page=>params[:page],:group => "#{table_name}.id"}.merge(@report.having_param)
    @search_results = search.paginate(query_parameters)
  end

  def to_csv
    parameters = {:id => params[:id]}
    csv_export('report', 'generate_custom_csv_file', parameters) 
  end

  def delete
    if Report.destroy params[:id]
      flash[:notice]="#{t('report_deleted_successfully')}."
    else
      flash[:notice]="#{t('report_delete_error')}."
    end
    redirect_to :action=>'index'
  end


  private

  def make_report_columns
    @report_column_hash = {}
    fields_to_display=@model.fields_to_display
    unless Configuration.enabled_roll_number?
      fields_to_display-= [:roll_number]
    end
    fields_to_display.each do |col|
      col.each do |key,value|
        @report_column_hash[key]=[] unless @report_column_hash.key?(key)
        value.each do |v|
          case v
          when Hash
            v.each do |assoc, methods|
              methods.each do |m|
                @report_column_hash[key] <<@report.report_columns.build(:method=>m,:title=>t((assoc.to_s + "_" + m.to_s)), :association_method => assoc)
              end
            end
          when Symbol
            @report_column_hash[key] << @report.report_columns.build(:method=>v,:title=>t(v),:association_method => nil)
          end
        end
      end
    end
    @model.additional_field_methods.each do |col|
      @report_column_hash[:main] << @report.report_columns.build(:method=>col,:title=>col.to_s.titleize)
    end
    if @model_name == "Employee"
      @model.bank_field_methods.each do |col|
        @report_column_hash[:main] << @report.report_columns.build(:method=>col,:title=>col.to_s.titleize)
      end
    end
  end

  def csv_export(model, method, parameters)
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model, method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller=> :reports, :action => :csv_reports, :model => model, :method => method
  end
end
