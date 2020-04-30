class RecordsController < ApplicationController
  filter_access_to :all
  before_filter :login_required
  
  def index
    @record_group=RecordGroup.find(params[:record_group_id])
    @records=@record_group.records.all(:order=>'records.priority')
  end
  def new
    @record_group=RecordGroup.find(params[:record_group_id])
    @record = @record_group.records.build(:multi_select_type=>'single_select')
    @record.record_field_options.build    
    @record.record_field_options.build
  end

  def create
    @record_group=RecordGroup.find(params[:record_group_id])
    @all_details = Record.find(:all,:order=>"priority ASC")
    priority = 1
    unless @all_details.empty?
      last_priority = @all_details.map{|r| r.priority}.compact.sort.last
      priority = last_priority + 1
    end
    @record = @record_group.records.new(params[:record])
    @record.priority = priority
    if @record.save
      flash[:notice] = "#{t('record_added')}"
      redirect_to :controller => "records", :action => "index",:record_group_id=>@record_group.id
    else
      if @record.record_field_options.blank?
        @record.record_field_options.build
        @record.record_field_options.build
      end
      render 'new'
    end
  end

  def edit
    @record_group=RecordGroup.find(params[:record_group_id])
    @record = Record.find(params[:id])
    if @record.record_field_options.blank?
      @record.record_field_options.build
      @record.record_field_options.build
    end
    render 'new' unless @record.student_records.present?
    flash[:notice] = "#{t('edit_not_allowed')}" if @record.student_records.present?
    redirect_to :controller => "records", :action => "index",:record_group_id=>@record_group.id if @record.student_records.present?
  end

  def update
    @record_group=RecordGroup.find(params[:record_group_id])
    @record=Record.find(params[:id])
    if @record.update_attributes(params[:record])
      flash[:notice] = "#{t('record_updated')}"
      redirect_to :controller => "records", :action => "index",:record_group_id=>@record.record_group_id
    else
      if @record.record_field_options.blank?
        @record.record_field_options.build
        @record.record_field_options.build
      end
      render :action=>"new"
    end
  end

  def update_priority
    @record_group=RecordGroup.find(params[:record_group_id])
    @record_group.update_attributes(params[:record_group])
    @records=@record_group.records.all(:order=>'records.priority')
    render :update do |page|
      page.replace_html 'other_details',:partial=>'records'
      page.replace_html 'flash-msg',:text=>"<p class='flash-msg'> #{t('record_priority_updated')}</p>"
    end
  end

  def destroy
    record=Record.find(params[:id])
    if record.destroy
      flash[:notice]="#{t('record_destroyed')}"
    else
      flash[:notice]="#{t('record_not_destroyed')}"
    end
    redirect_to :action=>'index' ,:record_group_id=>params[:record_group_id]
  end

  def preview
    @record_group=RecordGroup.find(params[:id],:include=>{:records=>:record_field_options},:order=>'records.priority')
  end

  def cancel
    @record_group=RecordGroup.find(params[:record_group_id])
    @records=@record_group.records.all(:order=>'records.priority')
    render :update do |page|
      page.replace_html 'other_details',:partial=>'records'
    end
  end
  
end
