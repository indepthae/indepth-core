class RoomAllocateController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  def index
    
  end
  def search_ajax
    @students = Student.find(:all,
      :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
        "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
        "#{params[:query]}", "#{params[:query]}" ],
      :order => "batch_id asc,first_name asc") unless params[:query] == ''
    @students.reject! {|s| !s.current_allocation.blank? } unless @students.nil?
    render :partial => "search_ajax"
  end

  def assign_room
    @student = Student.find params[:id]
    @hostels = Hostel.all
    if @student.gender.downcase=="f"
      @hostels.reject!{|h| h.hostel_type=="Gents"}
    else
      @hostels.reject!{|h| h.hostel_type=="Ladies"}
    end
  end

  def room_details
    @room_details = RoomDetail.find_all_by_hostel_id params[:hostel_id]
    @student =Student.find params[:student_id]
    render :partial=>'room_details'
  end

  def allocate
    @room = RoomAllocation.find_by_student_id(params[:student_id], :conditions => "is_vacated is false")
    @student =Student.find params[:student_id]
    @hostels = Hostel.all
    if @student.gender.downcase=="f"
      @hostels.reject!{|h| h.hostel_type=="Gents"}
    else
      @hostels.reject!{|h| h.hostel_type=="Ladies"}
    end
    unless @room.nil?
      flash[:notice] = "#{t('room_already_allocated_for_the_person')}"
      redirect_to :controller=> 'room_allocate', :action => 'index'
    else
      @room_details = RoomDetail.find params[:id]
   
      room_allocate = RoomAllocation.new
      room_allocate.student_id = params[:student_id]
      room_allocate.room_detail_id = params[:id]
      #room_allocate.is_vacated = false
      if room_allocate.save
        flash[:notice] = "#{t('room_allocated_for')} #{room_allocate.student.full_name}"
        redirect_to :controller=> 'room_allocate', :action => 'index'
      else
        flash[:warn_notice] = "#{t('cant_allocacte')}"
        @room_details = RoomDetail.find_all_by_hostel_id(@room_details.hostel_id)
        render :assign_room
      end

    end
  end

  def vacate
    @room_allocation = RoomAllocation.find params[:id]
    @room_detail = RoomDetail.find @room_allocation.room_detail_id
    if er=RoomAllocation.update(@room_allocation.id, :is_vacated =>true)
      flash[:notice] = "#{t('student_has_been_vacated_from_the_room')}"
    else
      flash[:warn_notice] = "#{er.errors.full_messages}"
    end
    redirect_to @room_detail
  end

  def change_room
    @room = RoomAllocation.find params[:id]
    @student = Student.find @room.student_id
    @hostels = Hostel.all
    if @student.gender.downcase=="f"
      @hostels.reject!{|h| h.hostel_type=="Gents"}
    else
      @hostels.reject!{|h| h.hostel_type=="Ladies"}
    end
  end
  def change_room_details
    @room_details = RoomDetail.find_all_by_hostel_id params[:hostel_id]
    @student =Student.find params[:student_id]
    @allocate =RoomAllocation.find params[:allocate_id]
    render :partial=>'change_room_details'
  end

  def relocate
    @room = RoomAllocation.find params[:allocate_id]
    @room_detail = RoomDetail.find params[:id]
    if @room.room_detail_id == @room_detail.id
      flash[:notice] = "#{t('student_is_already_allocated_to_same_room')}"
      redirect_to @room_detail
    else
      RoomAllocation.update(@room.id, :room_detail_id=>params[:id])   
      flash[:notice]="#{t('re_allocated_successfully')}"
      redirect_to @room_detail
    end
  end

end
