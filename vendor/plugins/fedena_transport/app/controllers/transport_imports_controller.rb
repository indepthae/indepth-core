class TransportImportsController < ApplicationController
  
  before_filter :login_required
  filter_access_to :all  
  before_filter :academic_year_id, :only=>[:index, :create, :search_passengers]
  
  check_request_fingerprint :create
  
  def new
    @transport_import = TransportImport.new
    @academic_years_to = AcademicYear.all
    @academic_years_from = AcademicYear.all_except_one(@transport_import.import_to_id)
  end
  
  def fetch_academic_years
    @academic_years_to = AcademicYear.all_except_one(params[:academic_year_id])
    render :update do |page|
      if @academic_years_to.present?
        @import_from = params[:academic_year_id]
        page.replace_html 'import_from', :partial=>'import_to_academic_year'
      else
        page.replace_html 'import_from', :text=>"<p class='flash-msg'>#{t('no_academic_year_to_import')}</p>"
      end
      page.replace_html 'import_form', :text=>''
    end
  end
  
  def update_import_form
    render :update do |page|
      if params[:academic_year_id].present?
        @transport_import = TransportImport.new
        @completed_imports = TransportImport.imported_section(params[:academic_year_id], params[:import_from])
        page.replace_html 'import_form', :partial=>'transport_import_form'
      else
        page.replace_html 'import_form', :text=>''
      end
    end
  end
  
  def create
     @transport_import = TransportImport.new(params[:import_transport])
      if @transport_import.save
        flash[:notice] = t('transport_importing_is_in_queue')
        redirect_to :action => :show
      else
        @academic_years_to = AcademicYear.all
        @academic_years_from = AcademicYear.all_except_one(@transport_import.import_to_id)
        @completed_imports = TransportImport.imported_section(@transport_import.import_from_id, @transport_import.import_to_id)
        render :new
      end
  end
  
  def show
    @imports = TransportImport.all(:order => "created_at DESC", :include => [:import_from, :import_to])
  end
  
  def update
    import = TransportImport.find params[:id]
    import.import
    flash[:notice] = t('transport_importing_is_in_queue')
    redirect_to :action=>:import_logs
  end
  
  
end
