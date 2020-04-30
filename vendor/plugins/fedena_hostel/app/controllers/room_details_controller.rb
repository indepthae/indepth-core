class RoomDetailsController < ApplicationController
  before_filter :login_required
  before_filter :set_precision
  filter_access_to :all
  def index
    @hostels = Hostel.all
  end

  def update_room_list
    #@room_details = RoomDetail.find_all_by_hostel_id params[:hostel_id]
    @room_details = RoomDetail.paginate(:conditions=>["hostel_id=?",params[:hostel_id]], :page=>params[:page])
    render :partial=>'room_list'
  end

  def new
    @room_detail = RoomDetail.new
    @hostel = Hostel.all
    unless params[:hostel_id].nil?
      @selected=Hostel.find params[:hostel_id]
    end
    @additional_fields = RoomAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"room_additional_field_options")
    @hostel_additional_fields = @additional_fields.map{|a| @room_detail.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id)}
  end
  
  def create
    @room_detail = RoomDetail.new(params[:room_detail])
    @hostel = Hostel.all
    if params[:room][:count].to_i == 0
      if @room_detail.save
        @hostel = Hostel.find @room_detail.hostel_id
        flash[:notice]="#{t('room_has_been_created')}"
        redirect_to room_details_path
      else
        @additional_fields = RoomAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"room_additional_field_options")
        @additional_fields.each{|a| @room_detail.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id) unless @room_detail.hostel_room_additional_details.collect(&:hostel_room_additional_field_id).include? a.id}
        @room_additional_details=@room_detail.hostel_room_additional_details
        @room_additional_details=@room_additional_details.sort_by{|x| x.hostel_room_additional_field.priority}
        render 'new'
      end
    else
      count = params[:room][:count].to_i
      @params = params[:room_detail]
      room_number = params[:room_detail][:room_number]
      @params.delete('room_number')
      saved = 0
      if count.to_i <= 300
        count.times do |c|
          @params["room_number"] = room_number
          @room_detail = RoomDetail.create(@params)
          unless @room_detail.id.nil?
            room_split = room_number.to_s.scan(/[A-Z]+|\d+/i)
            if room_split[1].blank?
              room_number = room_split[0].next
            else
              room_number = room_split[0]+room_split[1].next
            end
            saved += 1
            @room_detail = ''
          end
        end
      else
        @room_detail.errors.add_to_base("Maximum rooms should be less than 300")
      end
      if saved == count
        @hostel = Hostel.find params[:room_detail][:hostel_id]
        flash[:notice]="#{t('room_has_been_created')}"
        redirect_to room_details_path
      else
        @additional_fields = RoomAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"room_additional_field_options")
        @additional_fields.each{|a| @room_detail.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id) unless @room_detail.hostel_room_additional_details.collect(&:hostel_room_additional_field_id).include? a.id}
        @room_additional_details=@room_detail.hostel_room_additional_details
        @room_additional_details=@room_additional_details.sort_by{|x| x.hostel_room_additional_field.priority}
        render 'new'
      end
    end
  end

  def destroy
    @room_detail = RoomDetail.find(params[:id])
    hostel_id = @room_detail.hostel_id
    @vacant = RoomAllocation.find_all_by_room_detail_id(params[:id], :conditions=>["is_vacated is false"])
    if @vacant.size == 0
      @room_detail.destroy
      flash[:message2]=''
      flash[:message]="#{t('room_has_been_successfully_deleted')}"
    else
      flash[:message]=''
      flash[:message2]="#{t('unable_to_delete_the_room_when_allocated')}"
    end
    @room_details = RoomDetail.paginate(:conditions=>["hostel_id=#{hostel_id}"], :page=>params[:page])
    render :update do |page|
      page.replace_html 'room-list', :partial=>'room_list'
    end
  end

  def edit
    @room_details = RoomDetail.find(params[:id])
    @additional_fields = RoomAdditionalField.find(:all, :conditions=> "is_active = true and type= 'RoomAdditionalField'", :order=>"priority ASC",:include=>"room_additional_field_options")
    @room_additional_details = @room_details.hostel_room_additional_details.all(:conditions=>"hostel_room_additional_fields.is_active = true and hostel_room_additional_fields.type='RoomAdditionalField'",:include=>"hostel_room_additional_field")
    @additional_fields.select{|a| @room_additional_details.push(@room_details.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id)) unless @room_additional_details.collect(&:hostel_room_additional_field_id).include?(a.id)}
    @room_additional_details=@room_additional_details.sort_by{|x| x.hostel_room_additional_field.priority}
  end

  def update
    @room_details = RoomDetail.find(params[:id])
    if @room_details.update_attributes(params[:room_detail])
      flash[:notice]="#{t('room_details_successfully_updated')}"
      redirect_to room_details_path
    else
      @additional_fields = RoomAdditionalField.find(:all, :conditions=> "is_active = true and type= 'RoomAdditionalField'", :order=>"priority ASC",:include=>"room_additional_field_options")
      @room_additional_details = @room_details.hostel_room_additional_details.all(:conditions=>"hostel_room_additional_fields.is_active = true and hostel_room_additional_fields.type='RoomAdditionalField'",:include=>"hostel_room_additional_field")
      @additional_fields.each{|a| @room_details.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id) unless @room_details.hostel_room_additional_details.collect(&:hostel_room_additional_field_id).include? a.id}
      @room_additional_details=@room_details.hostel_room_additional_details.select{|a| a.hostel_room_additional_field.is_active==true}
      @room_additional_details=@room_additional_details.sort_by{|x| x.hostel_room_additional_field.priority}
      render :action => "edit"
    end
  end

  def show
    @room_details = RoomDetail.find params[:id]
    @students = @students = RoomAllocation.find_all_by_room_detail_id_and_is_vacated(params[:id],false).sort_by{|s| s.student.full_name.downcase unless s.student.nil?}
    @students.reject!{|x|x.student.nil?}
    @additional_details=@room_details.hostel_room_additional_details.all(:conditions=>"hostel_room_additional_fields.is_active = true and hostel_room_additional_fields.type='RoomAdditionalField'",:include=>"hostel_room_additional_field")
    @additional_details=@additional_details.sort_by{|x| x.hostel_room_additional_field.priority}
  end

  

  def sort_by
    sort = params[:sort][:on]
    @room_details = RoomDetail.search(:status_like=>"#{sort}").paginate(:all,:page=>params[:page],:include=>:tags)
    @count = @room_details.total_entries
    render(:update) do |page|
      page.replace_html 'hostels', :partial=>'hostels'
    end
  end

  def add_additional_details
    @all_details = RoomAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = RoomAdditionalField.new
    @room_additional_field_option = @additional_field.room_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = RoomAdditionalField.new(params[:room_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "room_details", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = RoomAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = RoomAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = RoomAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = RoomAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = RoomAdditionalField.new
    @additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RoomAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = RoomAdditionalField.find(params[:id])
    @room_additional_field_option = @additional_field.room_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:room_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    rooms = HostelRoomAdditionalDetail.find(:all ,:conditions=>"hostel_room_additional_field_id = #{params[:id]}")
    if rooms.blank?
      HostelRoomAdditionalField.find(params[:id]).destroy
      @additional_details = HostelRoomAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
      @inactive_additional_details = HostelRoomAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
      flash[:notice]="Additional field deleted successfully"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="Additional field is in use and cannot be deleted"
      redirect_to :action => "add_additional_details"
    end
  end



end
