#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class NewsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  filter_access_to :delete_comment,:attribute_check => true,:load_method => lambda {NewsComment.find(params[:id])}
  # def add
  #   if request.post?
  #     @news = News.new(params[:news])
  #     @news.author = current_user
  #     if @news.save
  #       sms_setting = SmsSetting.new
  #       if sms_setting.application_sms_active
  #         students = Student.find(:all,:select=>'phone2',:conditions=>'is_sms_enabled = true')
  #       end
  #       flash[:notice] = "#{t('flash1')}"
  #       redirect_to :controller => 'news', :action => 'view', :id => @news.id
  #     end
  #   else
  #     @news=News.new
  #     @news_attachment=@news.news_attachments.build
  #   end
  # end
  def add
    redirect_to new_news_path
  end
  
  def new
    @news=News.new
    @news_attachment=@news.news_attachments.build
    # render :add
  end
  
  def create
    @news = News.new(params[:news])
    @news.author = current_user
    if @news.save
      sms_setting = SmsSetting.new
      if sms_setting.application_sms_active
        students = Student.find(:all,:select=>'phone2',:conditions=>'is_sms_enabled = true')
      end
      flash[:notice] = "#{t('flash1')}"
      redirect_to :controller => 'news', :action => 'view', :id => @news.id
    else
      @news.news_attachments = []
      @news_attachment=@news.news_attachments.build
      render :action => :new
    end
  end
  
  def add_comment
    @cmnt = NewsComment.new(params[:comment])
    @current_user = @cmnt.author = current_user
    @is_moderator = @current_user.admin? || @current_user.privileges.include?(Privilege.find_by_name('ManageNews')) 
    @cmnt.is_approved =true if @is_moderator
    @cmnt.save
    show_comments_associate(@cmnt.news.id)
  end
  
  def show_pending_comments
    show_comments_associate(params[:id], params[:page])
    render :update do |page|
        page.replace_html "comments-list", :partial=>"pending_comments"
    end
  end
  
  def show_approved_comments
    show_comments_associate(params[:id], params[:page])
    render :update do |page|
        page.replace_html "comments-list", :partial=>"comment"
    end
  end
  
  def approve_comment
    @comment = NewsComment.find(params[:id])
    news_id = @comment.news_id
    status = @comment.is_approved ? false : true
    @comment.update_attributes(:is_approved => status)
    show_comments_associate(news_id)
  end

  def all
    @news = News.paginate :page => params[:page]
  end

  def delete
    @news = News.find(params[:id]).destroy
    flash[:notice] = "#{t('flash2')}"
    redirect_to :controller => 'news', :action => 'index'
  end

  def delete_comment
    @comment = NewsComment.find(params[:id])
    news_id = @comment.news_id
    @comment.destroy
    show_comments_associate(news_id)
  end

  def edit
    @news = News.find(params[:id])
    @news_attachment=@news.news_attachments.build if @news.news_attachments.empty?
    if request.post? and @news.update_attributes(params[:news])
      flash[:notice] = "#{t('flash3')}"
      redirect_to :controller => 'news', :action => 'view', :id => @news.id
    end
  end
  def update
    @news = News.find(params[:id])
    if @news.update_attributes(params[:news])
      flash[:notice] = "#{t('flash3')}"
      redirect_to :controller => 'news', :action => 'view', :id => @news.id
    else
      render :edit
      # redirect_to :controller => 'news', :action => 'edit', :id => @news.id
    end
  end
  def index
    @current_user = current_user
    conditions = ["DATE(created_at) between ? and ?",(Date.today - 3.months),Date.today]
    @all_news = News.find(:all,:conditions => conditions)
    @news = @all_news.paginate(:per_page => 10,:order=>"created_at DESC",:page =>params[:page], :conditions => conditions,:include=>:comments)
    @news_count = @all_news.count
  end
  
  def load_news
    @query = params[:query]
    if params[:query].present?
      conditions = ["title LIKE ? or content LIKE ?", "%#{params[:query]}%","%#{params[:query]}%"  ]
    elsif params[:search_since].present?
      if params[:search_since] == "all"
        conditions = []
      else
        conditions = ["DATE(created_at) between ? and ?",(Date.today - params[:search_since].to_i.months),Date.today]
      end
    else
      conditions = []
      if params[:filter].present?
        conditions = ["DATE(created_at) between ? and ?",(Date.today - 3.months),Date.today]
      end
    end
    @news = News.paginate(:per_page => 10,:order=>"created_at DESC",:page=>params[:page], :conditions => conditions,:include=>:comments) #unless params[:query] == ''
    @news_count = News.find(:all,:conditions => conditions).count
    @page_num = params[:page]
    render :update do |page|
      page.replace_html "news-div", :partial => "list_news"
      if params[:query].present?
        page.replace_html "filter-div", :partial => "results_notice"             
        page.replace_html "clear-div", :partial => "clear_link" 
      else
        unless params[:search_since].present?
          page.replace_html "filter-div", :partial => "filter_news"
          page.replace_html "clear-div", :text => ""
        end        
      end
    end
  end
  
  def search_news_ajax
    @news = nil
    conditions = ["title LIKE ?", "%#{params[:query]}%"]
    @news = News.find(:all, :conditions => conditions) unless params[:query] == ''
    render :layout => false
  end

  def view
    @news=News.find(params[:id])
    redirect_to @news
    #show_comments_associate(params[:id], params[:page])
  end
  
  def show
    show_comments_associate(params[:id], params[:page])
    render :view
  end
  
  def load_comments
    show_comments_associate(params[:id], params[:page])
    render :update do|page|
      if Configuration.get_config_value("EnableNewsCommentModeration") == "0"
        page.replace_html "comments-list", :partial=>"all_comments"
      else
        if params[:is_approved]
          page.replace_html "comments-list", :partial=>"comment"
        else
          page.replace_html "comments-list", :partial=>"pending_comments"
        end
      end
    end
  end
  
  def comment_view
    show_comments_associate(params[:id], params[:page])
    render :update do |page|
      page.replace_html 'comments-list', :partial=>"comment"
    end
  end

  private

  def show_comments_associate(news_id, params_page=nil)
    @news = News.find(news_id, :include=>[:author])
    @current_user = current_user
    @is_moderator = @current_user.admin? || @current_user.privileges.include?(Privilege.find_by_name('ManageNews')) 
    @comments = @news.comments.paginate(:order=>"created_at DESC",:page => params_page, :per_page => 10)
    @approved_comments=@news.comments.viewable_comments.paginate(:page => params_page, :per_page => 10)
    @pending_comments=@news.comments.pending_comments.paginate(:page => params_page, :per_page => 10,:order=>"created_at DESC")
    @config = Configuration.find_by_config_key('EnableNewsCommentModeration')
    @permitted_to_delete_comment_news = permitted_to? :delete_comment , :news
  end

end
