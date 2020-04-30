class CourseExamGroupsController < ApplicationController
  before_filter :login_required
  before_filter :has_required_params,:only=>[:list_tabs,:list_exam_batches]
  filter_access_to :all, :except=>[:list_tabs,:list_exam_batches,:index]
  filter_access_to [:list_tabs,:list_exam_batches], :attribute_check=>true, :load_method => lambda { Course.find(params[:course_id])}
  filter_access_to [:index], :attribute_check=>true, :load_method => lambda { current_user}

  def index
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      @courses=Course.has_batches.uniq.sort_by(&:course_name)
    elsif @current_user.is_a_batch_tutor
      @courses=[]
      @courses+=Course.all(:joins=>{:batches=>:employees},:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses+=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses = @courses.sort_by(&:course_name)
      @courses.uniq!
    elsif @current_user.is_a_subject_teacher
      @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    else
      @courses=[]
    end
    batch_exam_details if params[:course_id].present?
  end

  def new
    get_respective_courses
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @selectd_batch_ids=params[:batch_id].to_a
      @course=@batch.course
      @batches=@batch.to_a
      unless @course.nil?
        check_course_exam_type
      end
      @course_exam_group=CourseExamGroup.new()
    end
  end

  def edit
    @course_exam_group=CourseExamGroup.find(params[:id])
    @course=@course_exam_group.course
    check_course_exam_type
  end

  def update
    @course_exam_group=CourseExamGroup.find(params[:id])
    @course=@course_exam_group.course
    check_course_exam_type
    if @course_exam_group.update_attributes(params[:course_exam_group])
      flash[:notice] =  "#{t('flash_msg10')}"
      redirect_to @course_exam_group
    else
      deliver_plugin_block :fedena_reminder do
        @course_exam_group.set_alert_settings(params.fetch(:course_exam_group,{})[:event_alerts_attributes])
      end
      render "add_exams"
    end
  end

  def  update_imported_exams
    @course_exam_group = CourseExamGroup.find(params[:id],:include=>:exam_groups)
    @course_exam_group.new_batch_ids = params[:new_batch_ids]
    @course = @course_exam_group.course
    check_course_exam_type
    if @course_exam_group.update_attributes(params[:course_exam_group])
      flash[:notice] =  "#{t('flash_msg10')}"
      redirect_to @course_exam_group
    else
      render "add_exams"
    end
  end

  def create
    @course_exam_group=CourseExamGroup.new(params[:course_exam_group])
    @course=@course_exam_group.course
    check_course_exam_type
    if @course_exam_group.save
      flash[:notice] =  "#{t('exam_groups.flash1')}"
      redirect_to @course_exam_group
    else
      get_respective_courses
      @selectd_batch_ids=params[:course_exam_group][:new_batch_ids].to_a
      @batches=@course.batches.active unless params[:from]=='batch'
      @batch=Batch.find(params[:course_exam_group][:new_batch_ids]).first if params[:from]=='batch' #  batch id is an array, so it will return array of result
      @batches=@batch.to_a if params[:from]=='batch'
      render "new"
    end
  end

  def show
    @course_exam_group = CourseExamGroup.find(params[:id],:include=>:course)
    @inactive_count= @course_exam_group.exam_groups.inactive.all.count > 0 #to check inactive/active button need to show or not
    @course=@course_exam_group.course
    @is_active=true
    @course_exam_group.exam_groups_mode = :inactive if params[:status] == 'inactive'
    @is_active=params[:status] == 'active' if params[:status].present?
    @show_add_exam_button=@course_exam_group.new_exams.count > 0
    @show_batch_button = @course_exam_group.exam_groups_mode == :active && (@course.batches.active.count - @course_exam_group.exam_groups.count) <= 0
    batches_list
  end
  
  def new_batches
    @course_exam_group = CourseExamGroup.find(params[:id])
    batch_ids = @course_exam_group.batch_ids
    @available_batches = Batch.find_all_by_course_id(@course_exam_group.course_id,:conditions=>["id not in (?) and is_deleted=? and is_active=?",batch_ids,false,true])
  end

  def update_course_exam_group
    @course_exam_group=CourseExamGroup.find(params[:id],:include=>:course)
    @course=@course_exam_group.course
    check_course_exam_type
    if @course_exam_group.update_attributes(params[:course_exam_group])
      flash[:notice] =  "#{t('exam_group_updated_succesfully')}"
    else
      @errors=@course_exam_group.errors.full_messages
    end
  end
  
  def add_batches
    unless params[:new_batch_ids].nil?
      @error=true
      @course_exam_group = CourseExamGroup.find(params[:id])
      if  @course_exam_group.add_batches(params[:new_batch_ids])
        @course_exam_group.new_batch_ids=params[:new_batch_ids]
        @check_subjects=@course_exam_group.new_batch_exams
      else
        @error=false
        @errors=@course_exam_group.errors.full_messages
      end
    else
      @errors=[t('select_atleast_one_batch')]
    end
    if params[:import_exams] and params[:new_batch_ids].present? and @error
      batch_id_array="j.param(#{{:new_batch_ids=>params[:new_batch_ids]}.to_json} )"
      if  @check_subjects.empty?
        respond_to do |format|
          format.js { render :action => 'add_batches' }
        end
      else
        render :js => "window.location = '/course_exam_groups/#{params[:id]}/add_exams?'+#{batch_id_array}"
      end
    else
      respond_to do |format|
        format.js { render :action => 'add_batches' }
      end
    end
  end

  def add_exams
    @course_exam_group = CourseExamGroup.find(params[:id],:include=>:course)
    @course_exam_group.new_batch_ids=params[:new_batch_ids] if params[:new_batch_ids].present?
    @course=@course_exam_group.course
    check_course_exam_type
    deliver_plugin_block :fedena_reminder do
      @course_exam_group.build_alert_settings
    end
  end

  def list_exam_batches
    batch_exam_details
    render(:update) do |page|
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
        page.replace_html 'right-panel', :partial=>'list_batches'
      else
        page.replace_html 'update_batch', :partial=>'list_batches'
      end
    end
  end

  def list_tabs
    unless params[:course_id].empty?
      batch_exam_details
      render(:update) do |page|
        if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl"))
          page.replace_html 'update_batch', :partial=>'list_tabs'
        else
          page.replace_html 'update_batch', :partial=>'list_batches'
        end
      end
    else
      render(:update) do |page|
        page.replace_html 'update_batch', :text=>''
      end
    end
  end
  # for  pagination partials
  def batch_wise_exam_groups
    @batch_wise_exam_groups=ExamGroup.paginate(:per_page=>5,:page=>params[:page],:conditions=>"course_exam_group_id is null and batches.course_id=#{params[:course_id]} and batches.is_active=true and batches.is_deleted=false",:joins=>:batch,:joins=>:batch,:select=>"exam_groups.*,batches.name as batch_name,exam_groups.batch_id as batch_id")
    render(:update) do |page|
      page.replace_html 'batch_wise_exam_group_div', :partial=>'batch_wise_exam_groups'
    end
  end
  def common_exam_groups
    @common_exam_groups=CourseExamGroup.paginate(:per_page=>5,:page=>params[:page],:joins=>:exam_groups,:group=>"course_exam_groups.id",:conditions=>{:course_id=>params[:course_id]})
    render(:update) do |page|
      page.replace_html 'common_exam_group_div', :partial=>'common_exam_groups'
    end
  end
  ###

  def list_exam_groups
    @batch_wise_exam_groups=ExamGroup.paginate(:per_page=>5,:page=>params[:page],:conditions=>"course_exam_group_id is null and batches.course_id=#{params[:course_id]} and batches.is_active=true and batches.is_deleted=false",:joins=>:batch,:joins=>:batch,:select=>"exam_groups.*,batches.name as batch_name,exam_groups.batch_id as batch_id")
    @common_exam_groups=CourseExamGroup.find_all_by_course_id(params[:course_id],:joins=>:exam_groups,:group=>"course_exam_groups.id").paginate(:per_page=>5,:page=>params[:page])
    render(:update) do |page|
      page.replace_html 'right-panel', :partial=>'list_exam_groups'
    end
  end

  def list_batches
    if params[:course_id].present?
      @course_exam_group=CourseExamGroup.new()
      @course=Course.find(params[:course_id])
      @batches=@course.batches.active
      check_course_exam_type
      @user_privileges = @current_user.privileges
      if !@current_user.admin? and !@user_privileges.map{|p| p.name}.include?('ExaminationControl') and !@user_privileges.map{|p| p.name}.include?('EnterResults')
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      end
      render(:update) do |page|
        page.replace_html 'update_batch', :partial=>"multi_batches",:locals=>{:course_exam_group=>@course_exam_group}
      end
    else
      render(:update) do |page|
        page.replace_html 'update_batch', :text=>""
      end
    end
  end
  private

  def batches_list
    @batches = @course_exam_group.exam_groups.paginate(:per_page=>10,:page=>params[:page],
      :joins=>["INNER JOIN batches join_batches ON join_batches.id = exam_groups.batch_id LEFT OUTER JOIN subjects ON subjects.batch_id=join_batches.id and subjects.is_deleted=false LEFT OUTER JOIN exams ON exams.exam_group_id = exam_groups.id"],
      :group=>"join_batches.id",
      :select=>"join_batches.name batch_name,exam_groups.id exam_group_id,join_batches.id batch_id,count(distinct exams.id) as exams_count,exam_groups.result_published,exam_groups.is_published,count(DISTINCT subjects.id) as subject_count",:conditions=>["join_batches.is_active=#{@is_active}"])
  end

  def batch_exam_details
    @batch_type=to_boolean(params[:batch_type])
    @course=Course.find(params[:course_id])
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      if @batch_type
        batch_query
      else
        unless @course.cce_enabled? or @course.icse_enabled?
          #@batches = Batch.paginate(:per_page=>10,:page=>params[:page],:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups INNER JOIN  grouped_exams ON grouped_exams.exam_group_id = exam_groups.id on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => { :is_deleted => false,:is_active =>  @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc")
          @batches = Batch.paginate(:per_page=>10,:page=>params[:page],:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => { :is_deleted => false,:is_active =>  @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc")
        else
          batch_query
        end
      end
    elsif @current_user.is_a_batch_tutor?
      batch_ids=[]
      batch_ids += @current_user.employee_record.batches.all(:conditions=>{:course_id=>params[:course_id]}).collect(&:id)
      @current_user.employee_record.subjects.each do |s|
        (batch_ids << s.batch.id)  if s.batch.course_id == params[:course_id].to_i
      end
      batch_ids.uniq!
      if @batch_type
        selected_batch_query(batch_ids)
      else
        unless @course.cce_enabled? or @course.icse_enabled?
          @batches = Batch.find_all_by_id(batch_ids,:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups INNER JOIN  grouped_exams ON grouped_exams.exam_group_id = exam_groups.id on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => { :is_deleted => false,:is_active => @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc").paginate(:per_page=>5,:page=>params[:page])
        else
          selected_batch_query(batch_ids)
        end
      end
    elsif @current_user.has_assigned_subjects?
      batch_ids = @current_user.employee_record.subjects.collect(&:batch_id)
      if @batch_type
        selected_batch_query(batch_ids)
      else
        unless @course.cce_enabled? or @course.icse_enabled?
          @batches = Batch.paginate(:per_page=>5,:page=>params[:page],:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups INNER JOIN  grouped_exams ON grouped_exams.exam_group_id = exam_groups.id on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => {:id=>batch_ids,:is_deleted => false,:is_active => @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc")
        else
          selected_batch_query(batch_ids)
        end
      end
    end
    end

  def batch_query
    @batches = Batch.paginate(:per_page=>10,:page=>params[:page],:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => { :is_deleted => false,:is_active =>  @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc")
  end

  def selected_batch_query(batch_ids)
    @batches = Batch.find_all_by_id(batch_ids,:select=>"exam_groups.id as exam_group_id,batches.id batch_id,batches.name batch_name,count(DISTINCT exam_groups.id) as count_exam_groups,sum(CASE WHEN date(exams.start_time) <= date('#{DateTime.now}') AND  date(exams.end_time) >= date('#{DateTime.now}') THEN 1 ELSE 0 END) as count_active_exams",:joins=>"LEFT OUTER JOIN exam_groups on exam_groups.batch_id=batches.id LEFT outer JOIN exams on exams.exam_group_id=exam_groups.id",:conditions => { :is_deleted => false,:is_active => @batch_type,:course_id=>params[:course_id]},:group=>"batches.id",:order=>"batches.updated_at desc").paginate(:per_page=>5,:page=>params[:page])
  end

  def to_boolean(str)
    str == 'true'
  end

  def check_course_exam_type
    @cce_exam_categories = CceExamCategory.all if @course.cce_enabled?
    @icse_exam_categories = IcseExamCategory.all if @course.icse_enabled?
  end

  def has_required_params
    handle_params_failure(params[:course_id],[],[['update_batch',{:text=>''}]])
  end
end
