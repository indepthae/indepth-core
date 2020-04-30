
class PlacementRegistrationsController<ApplicationController
  before_filter :login_required
  filter_access_to :all,:except=>[:show,:index]
  filter_access_to [:show],:attribute_check => true,:load_method => lambda {PlacementRegistration.find params[:id]}
#  filter_access_to [:index],:attribute_check => true,:load_method => lambda {PlacementRegistration.find params[:placementevent_id]}
  
  def index 
    @placementevent = Placementevent.find params[:placementevent_id]
    registrations = @placementevent.placement_registrations
    registrations = registrations.sort_by{|r| r.member.full_name.downcase}
    @placement_registrations =registrations.paginate :page=>params[:page] ,:per_page=>10

  end
  def show
    @placement_registration = PlacementRegistration.find params[:id]
  end
  def apply
    @placement_registration = PlacementRegistration.find params[:id]
    if @placement_registration.placementevent.is_active==true
      if  current_user.student? &&  current_user.student_record.id ==   @placement_registration.student.id
        if @placement_registration.update_attributes(:is_applied=>true)
          flash[:notice] = "#{t('flash1')}"
        else
          falsh[:notice] = "#{t('flash2')}"
        end
      else
        falsh[:notice] = "#{t('flash3')}"
      end
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to [@placement_registration.placementevent,@placement_registration]
  end

  def approve_registration
    @placement_registration = PlacementRegistration.find params[:id]
    status = ( ["0","1"].include? params[:status])? params[:status]:nil
    unless status.nil?
      @placement_registration.update_attributes :is_approved => status
      flash[:notice] = "#{t('flash5')} #{status=="0" ? t('rejected'):t('approved')} "
    end
    redirect_to placementevent_placement_registrations_path [@placement_registration.placementevent_id]
  end

  def approve_attendance
    @placement_registration = PlacementRegistration.find params[:id]
    status = ( ["0","1"].include? params[:status])? params[:status]:nil
    unless status.nil?
      @placement_registration.update_attributes :is_attended => status
      flash[:notice] = "#{t('the_student_has')} #{status=="0" ? t('not_attended'):t('attended')} #{t('the_recruitment_process')}"
    end
    redirect_to placementevent_placement_registrations_path [@placement_registration.placementevent_id]
  end

  def approve_placement
    @placement_registration = PlacementRegistration.find params[:id]
    status = ( ["0","1"].include? params[:status])? params[:status]:nil
    unless status.nil?
      @placement_registration.update_attributes :is_placed => status
      flash[:notice] = "#{t('the_placement_is')} #{status=="0" ? t('rejected'):t('approved')} "
    end
    redirect_to placementevent_placement_registrations_path [@placement_registration.placementevent_id]
  end

end
