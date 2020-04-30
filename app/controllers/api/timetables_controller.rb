class Api::TimetablesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @user = User.first(:conditions => ["username LIKE BINARY(?)",params[:username]])
    @timetable = Timetable.search(params[:search]).first
    if @user.student?
      @timetable_entries = TimetableEntry.search(:batch_name_equals => @user.student_record.batch.try(:name),:batch_course_code_equals => @user.student_record.batch.try(:code),:timetable_id_equals => @timetable.try(:id)).all
    elsif @user.employee?      
      is_permitted = (@current_user.admin? or @current_user == @user) # or @current_user.privileges.all.map(&:name).include? 'ManageTimetable'
      @timetable_entries = is_permitted ? @user.employee_record.timetable_entries.all(:conditions => ["timetable_id = ?",@timetable.try(:id)]) : []
#      @timetable_entries = TimetableEntry.search(:employee_id_equals => @user.employee_record.try(:id),:timetable_id_equals => @timetable.try(:id)).all
    else
      @timetable_entries = []
    end

    respond_to do |format|
      format.xml { render :timetable_entries}
    end
  end
  
  private

end
