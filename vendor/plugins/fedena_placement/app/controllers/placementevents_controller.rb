class PlacementeventsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except=>[:show]
  filter_access_to [:show],:attribute_check => true,:load_method => lambda {Placementevent.find params[:id]}
  def index
    @placementevents = Placementevent.active_placements.paginate :page=>params[:page]
    if current_user.student?
      @student = current_user.student_record
      @placementevents = @student.placementevents.active_placements.paginate :page=>params[:page]
    end
  end
  
  def archive
    @placementevents = Placementevent.inactive_placements.paginate :page=>params[:page]
    if current_user.student?
      @student = current_user.student_record
      @placementevents = @student.placementevents.inactive_placements.paginate :page=>params[:page]
    end
  end

  def new
    @placementevent =Placementevent.new
  end

  def show
    @placementevent = Placementevent.find params[:id]
    @placement_registration = PlacementRegistration.find_by_student_id_and_placementevent_id(current_user.student_record.id,@placementevent.id) if current_user.student?
#    if current_user.student and !@placementevent.students.include? current_user.student_record
#      flash[:notice] = "#{t('flash1')}"
#      redirect_to placementevents_path
#    end
  end

  def edit
    @placementevent = Placementevent.find params[:id]
    unless @placementevent.date>=Date.today
      flash[:notice]=t('flash_msg6')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def update
    @placementevent = Placementevent.find params[:id]
    if @placementevent.update_attributes(params[:placementevent])
      @event=Event.find(:first ,:conditions=>{:origin_id => params[:id], :origin_type => "Placementevent"})
       if @event.present?
        Event.update(@event.id,:start_date => params[:placementevent][:date], :end_date => params[:placementevent][:date], :description=> "#{t('company')}: #{params[:placementevent][:company]} <br/>#{t('details')}: #{params[:placementevent][:description]}")
      end
#      reminder_subject = "#{t('placement_cell')} #{@placementevent.company} on #{format_date(@placementevent.date,:format => :short_date)} "
#      reminder_body = "#{@placementevent.description} #{t('you_have_invited_the_placement_event')} #{format_date(@placementevent.date,:format => :short_date)} ,  #{t('confirm_your_registration')} "
      body = "<b>#{@placementevent.title}</b> : #{t('you_have_invited_the_placement_event')} #{format_date(@placementevent.date,:format => :short_date)}"
      links = {:target=>'view_placement_details',:target_param=>'placementevent_id',:target_value=>@placementevent.id}
      recipients_array = []
      @placementevent.placement_registrations.each do |s|
        student = Student.find_by_id s.student_id
        recipients_array << student.user_id if student.present?
      end
      inform(recipients_array,body,'Placement',links)
      flash[:notice]="#{t('flash2')}"
      redirect_to @placementevent
    else
      render :action=>:edit
    end
  end

  def create
    @placementevent = Placementevent.new(params[:placementevent])
    if @placementevent.save
      flash[:notice]="#{t('flash3')}"
      redirect_to @placementevent
    else
      render :action=>:new
    end
  end

  def destroy
    @placementevent = Placementevent.find params[:id]
    if @placementevent.is_active==false
      flag=1
    end
    if @placementevent.destroy
      Event.destroy_all(:origin_id => params[:id], :origin_type => "Placementevent")
    end
    flash[:notice] = "#{t('flash4')}"
    if flag==1
      redirect_to :action=>'archive'
    else
      redirect_to placementevents_path
    end
  end
  def deactivate
    @placementevent  = Placementevent.find params[:id]
    @placementevent.update_attribute(:is_active,false)
    flash[:notice] = "#{t('flash5')}"
    redirect_to @placementevent
  end
  
  def invite
    @batches = Batch.active
    @placementevent = Placementevent.find params[:id]
    @event=Event.find(:first ,:conditions=>{:origin_id => params[:id], :origin_type => "Placementevent"})
    if request.post?
      unless params[:invites].empty?
        @event=Event.create(:title=> "#{t('placement')}", :description=> "#{t('company')}: #{@placementevent.company} <br/>#{t('details')}: #{@placementevent.description}", :start_date=> @placementevent.date, :end_date=> @placementevent.date, :origin => @placementevent)if @event.nil?
        student_list = params[:invites].split(",")
        recipients_array = []
        student_list.each do |s|
          student = Student.find_by_id s
          unless student.nil?
            placement_registration =  student.placement_registrations.build(:placementevent_id=>@placementevent.id)
            if placement_registration.save
              UserEvent.create(:event_id=> @event.id, :user_id => student.user.id)
              recipients_array << student.user_id
            end
          end
        end
        body = "<b>#{@placementevent.title}</b> : #{t('you_have_invited_the_placement_event')} #{format_date(@placementevent.date,:format => :short_date)}"
        links = {:target=>'view_placement_details',:target_param=>'placementevent_id',:target_value=>@placementevent.id}
        inform(recipients_array,body,'Placement',links)
        flash[:notice] ="#{t('flash6')}"
        redirect_to @placementevent
      else
        flash[:warn_notice] ="#{t('flash8')}"
      end
    end
  end

  def update_students_list
    @students=[]
    unless params[:batch] == ""
      @batch = Batch.find params[:batch]
      @students = @batch.students.sort_by{|a| a.full_name.downcase}
    end
    render :update do |page|
      page.replace_html "students-list" ,:partial=>"students_list"
    end

  end

  def update_invite_list
    student_ids = params[:students].split(",")
    @students = student_ids.map{|s| Student.find_by_id  s}.sort_by{|a| a.full_name.downcase}
    render :update do |page|
      page.replace_html "invite-list" ,:partial=>"invites_list"
    end
  end
  
  def report
    @placementevent = Placementevent.find params[:id]
    
    @type = ( ["invited","applied","approved","attended","placed"].include? params[:report][:type].downcase) ? (params[:report][:type].downcase):nil
    unless @type.nil?
      @registrations = @placementevent.placement_registrations
      @registrations.reject! {|r| !r.is_applied?} if @type=="applied"
      @registrations.reject! {|r| !r.is_approved?} if @type=="approved"
      @registrations.reject! {|r| !r.is_attended?} if @type=="attended"
      @registrations.reject! {|r| !r.is_placed?} if @type=="placed"
      @students = @registrations.map{|r| r.member}.compact
    else
      flash[:notice]="#{t('flash7')}"
      redirect_to @placementevent
    end

  end

  def report_pdf
    @placementevent = Placementevent.find params[:id]

    @type = ( ["invited","applied","approved","attended","placed"].include? params[:report][:type].downcase) ? (params[:report][:type].downcase):nil

    unless @type.nil?
      @registrations = @placementevent.placement_registrations
      @registrations.reject! {|r| !r.is_applied?} if @type=="applied"
      @registrations.reject! {|r| !r.is_approved?} if @type=="approved"
      @registrations.reject! {|r| !r.is_attended?} if @type=="attended"
      @registrations.reject! {|r| !r.is_placed?} if @type=="placed"
      @students = @registrations.map{|r| r.member}
    else
      flash[:notice]="#{t('flash7')}"
      redirect_to @placementevent
    end
    render :pdf=>'placement_report'
  end
end
