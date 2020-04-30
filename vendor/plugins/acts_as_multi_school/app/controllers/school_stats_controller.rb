class SchoolStatsController < MultiSchoolController
  filter_access_to [:live_statistics,:live_statistics_ajax, :live_statistics_attendance,:live_statistics_report,:list_live_entities,:modify_user_live_entities,:statistics,:dashboard,:bookmark_paginate,:bookmark_destroy,:bookmark], :attribute_check=>true ,:load_method => lambda {admin_user_session}
  filter_access_to :all
  
  def live_statistics
    @entities=admin_user_session.school_stat.present?? admin_user_session.school_stat.live_stats : []
    attendance_entities=SchoolStats::DataEntity.attendance_entities.collect(&:name)
    @attendance_entities=@entities.select{|e| attendance_entities.include? e.to_sym}
    @entities=@entities.join(",")
    @attendance_entities=@attendance_entities.join(",")
  end

  def live_statistics_ajax
    @start_date=params[:start_date] || Date.today
    @end_date=params[:end_date] || Date.today
    @entity=params[:live_entity]
    @stats_hash = SchoolStats::DataEntity.load_live_entity(@entity.to_a,:start_date=>@start_date,:end_date=>@end_date,:school_ids=>get_school_ids)
    render(:update) do |page|
      page.replace_html   "stats-box_#{@entity}", :partial=>"live_reports"
    end
  rescue *SchoolStats::EXCEPTIONS => e
    logger.debug e.message
    render :file=>"public/404.html",:status=>404
  end

  def live_statistics_attendance
    @entity=params[:live_entity]
    @stats_hash = SchoolStats::DataEntity.load_live_entity(@entity.to_a,:start_date=>params[:start_date],:end_date=>params[:end_date],:school_ids=>get_school_ids)
    if request.xhr?
      render(:update) do |page|
        page.replace_html   "stat-attendance-live_#{@entity}", :partial=>"stat_attendance"
      end
    end
  end

  def live_statistics_report
    @start_date=params[:start_date] || Date.today
    @end_date=params[:end_date] || Date.today
    @statistics=SchoolStats::DataEntity.load_live_data_rows(params[:stat_path].to_s,:start_date=>@start_date,:end_date=>@end_date,:page=>params[:page],:per_page=>9,:school_ids=>get_school_ids)
  rescue *SchoolStats::EXCEPTIONS => e
    logger.debug e.message
    render :file=>"public/404.html",:status=>404
  end
  
  def list_live_entities
    available_entities=SchoolStats::DataEntity.live_entities.collect(&:name)
    @attendance_entities=SchoolStats::DataEntity.attendance_entities.collect(&:name)
    available_entities<< @attendance_entities
    @available_entities=available_entities.flatten.uniq
    @user_stats=admin_user_session.school_stat.present?? admin_user_session.school_stat.live_stats : []
    render :partial=>"list_live_entities"
  end

  def modify_user_live_entities
    admin_user=admin_user_session
    selected_stats=params[:live_stats].present?? params[:live_stats][:selected_stats] : []
    if admin_user.school_stat.present?
      admin_user.school_stat.update_attributes(:live_stats=>selected_stats)
    else
      admin_user.create_school_stat(:live_stats=>selected_stats)
    end
    redirect_to school_statistics_live_path
  end

  def statistics
    path=params[:stat_path].present?? params[:stat_path] : params[:section].present?? params[:section] : []
    @statistics = SchoolStats::DataEntity.load_entity(path,:school_id=>get_school_ids,:page=>params[:page],:per_page=>10)
    @schools=SchoolStats::DataEntity.load_schools(path,:school_id=>get_school_ids)
  rescue *SchoolStats::EXCEPTIONS => e
    logger.debug e.message
    render :file=>"public/404.html",:status=>404
  end

  def dashboard
    @bookmarks=admin_user_session.stat_bookmarks.paginate(:order=>"id DESC",:per_page=>5,:page=>params[:page])
  end

  def bookmark_paginate
    @bookmarks=admin_user_session.stat_bookmarks.paginate(:order=>"id DESC",:per_page=>5,:page=>params[:page])
    render(:update) do |page|
      page.replace_html 'bookmarks', :partial=>"bookmarks"
    end
  end

  def bookmark
    bookmark=admin_user_session.stat_bookmarks.new(params[:bookmark])
    unless bookmark.save
      @error=true
    end
    render(:update) do |page|
      if @error
        page.replace_html 'alert',:text=>'<div class="alert alert-warning warn-notice pagination-centered" id="bookmark_alert"> <span>Bookmark was already saved.</span></div>'
      else
        page.replace_html 'alert',:text=>'<div class="alert alert-warning warn-notice pagination-centered" id="bookmark_alert"> <span>Bookmark was successfully saved.</span></div>'
      end
    end
  end

  def bookmark_destroy
    bookmark=StatBookmark.find params[:id]
    if bookmark.destroy
      flash[:notice]="Bookmark was successfully deleted"
    else
      flash[:notice]="Unable to delete the bookmark"
    end
    redirect_to dashboard_school_stats_path
  end

  private

  def get_school_ids
    school_group = admin_user_session.school_group
    school_ids=school_group.schools.present?? school_group.schools.all(:select=>"id",:conditions=>{:is_deleted=>false}).collect(&:id) : [0]
    school_ids.empty? ? [0] : school_ids
  end
  
end
