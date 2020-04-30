class DisciplineComplaintsController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:show,:download_attachment,:decision]
  filter_access_to [:show,:download_attachment,:decision,:edit], :attribute_check=>true
  filter_access_to :create_comment,:attribute_check=>true,:load_method => lambda { DisciplineComplaint.find(params[:complaint_id] || params[:child_id]) }
  before_filter :complaint_present, :only => [:edit,:update,:destroy,:show,:list_comments,:decision,:decision_close]
  def index
    @discipline_complaints=DisciplineComplaint.sort_discipline(params[:sort_param],current_user.id).paginate(:page => params[:page], :per_page=>10)
    @csv_complaints=DisciplineComplaint.sort_discipline(params[:sort_param],current_user.id)
    if request.xhr?
      render(:update) do |page|
        page.replace_html'list',:partial=>'sort_pending'
      end
    end
  end

  def new
    @discipline_complaint=DisciplineComplaint.new
    @last_registered_complaint=DisciplineComplaint.cmp_no
    @date=Date.today
    @discipline_attachment = DisciplineAttachment.new
  end

  def create
    attachment_fields = params[:discipline_attachment][:attachment] if params[:discipline_attachment].present? and params[:discipline_attachment][:attachment].present?
    @discipline_complaint=DisciplineComplaint.new(params[:discipline_complaint])
    @discipline_complaint.user_id=current_user.id
    @master=@discipline_complaint.build_discipline_master("user_id"=>current_user.id)
    if attachment_fields.present?
      @attachment=@master.discipline_attachments.build(:attachment=>attachment_fields)
      @discipline_complaint.attachment_file_size=@attachment.attachment_file_size
    end
    if @discipline_complaint.save
      if @master.save
        if attachment_fields.present?
          @attachment.save
        end
      end
      recipients=@discipline_complaint.discipline_participations.reject{|e| e.user_id==current_user.id}.collect(&:user_id)
      body ="#{t('you_are_a_participant_on_complaint')} <b>#{@discipline_complaint.subject}</b>"
      links = {:target=>'view_complaint',:target_param=>'discipline_complaint_id',:target_value=>@discipline_complaint.id}
      inform(recipients,body,'Discipline',links)
      redirect_to :controller=>"discipline_complaints", :action=>"index"
      flash[:notice]="#{t('flash2')}"
    else
      @discipline_attachment = DisciplineAttachment.new
      @date=params[:discipline_complaint][:trial_date]
      params[:discipline_complaint][:complaint_no].present? ? @last_registered_complaint = params[:discipline_complaint][:complaint_no] : @last_registered_complaint =nil
      render :action=>"new"
    end
  end

  def edit
    @discipline_attachment=@discipline_complaint.discipline_master.discipline_attachments.last
    @discipline_attachment_new = DisciplineAttachment.new
  end

  def update
    attachment_fields = params[:discipline_attachment][:attachment] if params[:discipline_attachment].present? and params[:discipline_attachment][:attachment].present?
    participations=@discipline_complaint.discipline_participations.all
    @discipline_complaint.action_taken=0;
    @discipline_attachment=@discipline_complaint.discipline_master.discipline_attachments.last
    @master=@discipline_complaint.discipline_master
    unless attachment_fields.nil?
      @attachment=@master.discipline_attachments.build(:attachment=>attachment_fields)
      @discipline_complaint.attachment_file_size=@attachment.attachment_file_size
    end
    if @discipline_complaint.update_attributes(params[:discipline_complaint])
      unless attachment_fields.nil?
        @attachment.save
      end
      new_participations=@discipline_complaint.discipline_participations.all
      @discipline_complaint.discipline_participations.each do |participation|
        participation.update_attributes(:action_taken=>false)
      end
      new_added=new_participations-participations
      recipients=participations.reject{|e| e.user_id==current_user.id}.collect(&:user_id)
      body1 ="#{t('the_complaint')} <b>#{@discipline_complaint.subject}</b> #{t('under_your_participatin_is_updated')}"
      links = {:target=>'view_complaint',:target_param=>'discipline_complaint_id',:target_value=>@discipline_complaint.id}
      inform(recipients,body1,'Discipline',links)
#      Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => current_user.id,
#          :recipient_ids => recipients,
#          :subject=>subject1,
#          :body=>body1))
      recipients=new_added.reject{|e| e.user_id==current_user.id}.collect(&:user_id)
      body2 ="#{t('you_are_a_participant_on_complaint')} <b>#{@discipline_complaint.subject}</b>"
      links = {:target=>'view_complaint',:target_param=>'discipline_complaint_id',:target_value=>@discipline_complaint.id}
      inform(recipients,body2,'Discipline',links)
#      Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => current_user.id,
#          :recipient_ids => recipients,
#          :subject=>subject2,
#          :body=>body2))
      redirect_to :controller=>"discipline_complaints", :action=>"index"
      flash[:notice]="#{t('flash1')}"
    else
      @discipline_attachment_new = DisciplineAttachment.new
      render :action=>"edit"
    end
  end

  def download_attachment
    upload = DisciplineAttachment.find(params[:id1])
    send_file upload.attachment.path,
      :filename => upload.attachment_file_name,
      :type => upload.attachment_content_type,
      :disposition => 'attachment'
  end

  def delete_attachment
    @discipline_attachment = DisciplineAttachment.find(params[:id])
    id=@discipline_attachment.discipline_participation.discipline_complaint.id
    @discipline_attachment.destroy
    redirect_to :controller=>"discipline_complaints",:action=>"edit",:id=>id
    flash[:notice]="#{t('flash6')}"
  end

  def destroy
    @discipline_complaint.destroy
    flash[:notice]="#{t('flash3')}"
    redirect_to:controller=>"discipline_complaints", :action=>"index"
  end

  def search_complaint_ajax
    if params[:query].present?
#      @discipline_complaints = DisciplineComplaint.sort_discipline("",current_user.id) & DisciplineComplaint.find(:all,:include=>[:discipline_master],
      @discipline_complaints = DisciplineComplaint.sort_discipline("",current_user.id) & DisciplineComplaint.find(:all,:include=>[:discipline_master],:joins=>{:discipline_participations=>:user},
        :conditions => "(subject LIKE \"#{params[:query]}%\"
                          OR complaint_no LIKE \"#{params[:query]}%\" OR users.first_name LIKE \"#{params[:query]}%\" OR users.last_name LIKE \"#{params[:query]}%\")",
        :order => "subject asc") unless params[:query] == ''
    else
      @discipline_complaints =DisciplineComplaint.sort_discipline("",current_user.id)
    end
    render :layout => false
  end

  def search_complainee
    students= User.active.find(:all, :conditions=>["student=1 AND (username LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>students.collect{|s| s.full_name.length+s.username.length > 20 ? s.full_name[0..(18-s.username.length)]+".. "+" - "+s.username : s.full_name+" - "+s.username},'data'=>students.collect(&:id)  }
  end

  def search_accused
    students= User.active.find(:all, :conditions=>["student=1 AND (username LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>students.collect{|s| s.full_name.length+s.username.length > 20 ? s.full_name[0..(18-s.username.length)]+".. "+" - "+s.username : s.full_name+" - "+s.username},'data'=>students.collect(&:id)  }
  end

  def search_juries
    juries= User.active.find(:all, :conditions=>["employee=1 AND (username LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>juries.collect{|s| s.full_name.length+s.username.length > 20 ? s.full_name[0..(14-s.username.length)]+".. "+" (Emp ID: "+s.username+")" : s.full_name+" (Emp ID: "+s.username+")"},'data'=>juries.collect(&:id)  }
  end

  def search_users
    users= User.active.find(:all, :conditions=>["(admin=1 OR employee=1 OR student=1)  AND (username LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>users.collect{|s| s.full_name.length+s.username.length > 20 ? s.full_name[0..(16-s.username.length)]+".. "+(s.student_record ? "(Adm No: ":"(Emp ID: " )+s.username+")" : s.full_name+(s.student_record ? "(Adm No: ":"(Emp ID: " )+s.username+")"},'data'=>users.collect(&:id)  }
  end

  def show
    @discipline_comments = @discipline_complaint.discipline_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    @privilege_admin=@discipline_complaint.discipline_participations.find_by_user_id(current_user.id)
    @privilege=((@privilege_admin.present?)||(current_user.admin?))
    jury_ids=@discipline_complaint.discipline_juries.collect(&:user_id)
    @close_privilege=(jury_ids.include?(current_user.id)) and (@discipline_complaint.action_taken==false)
    participation_ids=@discipline_complaint.discipline_participations.collect(&:user_id)
    @action_privillage=((((participation_ids.include?(current_user.id))||current_user.admin?)||DisciplineComplaint.is_privileged_user(current_user.id)) and (@discipline_complaint.action_taken==true))
    @discipline_attachment= @discipline_complaint.discipline_master.discipline_attachments.last
  end

  def list_comments
    @discipline_comments = @discipline_complaint.discipline_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    @privilege_admin=@discipline_complaint.discipline_participations.find_by_user_id(current_user.id)
    @privilege=((@privilege_admin.present?)||(current_user.admin?))
    render :update do |page|
      page.replace_html 'comments_list', :partial=>"discipline_complaints/comment"
    end
  end

  def create_comment
    if params[:comment] and params[:comment][:body]
      @discipline_complaint=DisciplineComplaint.find(params[:complaint_id])
      @privilege_admin=@discipline_complaint.discipline_participations.find_by_user_id(current_user.id)
      @privilege=((@privilege_admin.present?)||(current_user.admin?))
      @discipline_comment=@discipline_complaint.discipline_comments.build(:body=>params[:comment][:body],:user_id=>current_user.id)
      @discipline_comment.save
      @discipline_complaint.update_attributes(:updated_at=>Date.today)
      @discipline_comments = @discipline_complaint.discipline_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
      render(:update) do |page|
        page.replace_html "comments_list",:partial=>"comment"
        page.select('form').each { |f| f.reset }
      end
    elsif params[:child_id]
      @parent=DisciplineComment.find(params[:child_id])
      @discipline_complaint=DisciplineComplaint.find(@parent.commentable_id)
      @privilege_admin=@discipline_complaint.discipline_participations.find_by_user_id(current_user.id)
      @privilege=((@privilege_admin.present?)||(current_user.admin?))
      @discipline_comment=@parent.replies.build(:body=>params[:child_comment][:body],:user_id=>current_user.id)
      @discipline_comment.save
      @discipline_complaint.update_attributes(:updated_at=>Date.today)
      @discipline_comments = @discipline_complaint.discipline_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
      render(:update) do |page|
        page.replace_html "comments_list",:partial=>"comment"
      end
    end
  end

  def reply
    @child_comment=DisciplineComment.find(params[:id])
    render(:update) do |page|
      page.replace_html "reply#{params[:id]}",:partial=>'reply'
    end
  end

  def destroy_comment
    @comment=DisciplineComment.find(params[:id1])
    if @comment.commentable_type=="DisciplineComplaint"
      @discipline_complaint=DisciplineComplaint.find(@comment.commentable_id)
    else
      @discipline_complaint=DisciplineComplaint.find(DisciplineComment.find(@comment.commentable_id).commentable_id)
    end
    @comment.destroy
    @discipline_comments = @discipline_complaint.discipline_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    @privilege_admin=@discipline_complaint.discipline_participations.find_by_user_id(current_user.id)
    @privilege=((@privilege_admin.present?)||(current_user.admin?))
    render(:update) do |page|
      page.replace_html "comments_list",:partial=>"comment"
    end
  end

  def decision
    if (current_user.admin? || DisciplineComplaint.is_privileged_user(current_user.id))|| @discipline_complaint.discipline_participations.collect(&:user_id).include?(current_user.id)|| @discipline_complaint.discipline_participations.collect(&:user_id).include?(Student.find(Guardian.find_by_user_id(current_user.id).current_ward_id).user_id)
      @convicted=@discipline_complaint.discipline_accusations

      @verdict=DisciplineAction.new
    else
      redirect_to :controller=>"user" ,:action=>"dashboard"
      flash[:notice]="#{t('flash_msg4')}"
    end
    if request.post?
      @verdict=@discipline_complaint.discipline_actions.build(:body=>params[:verdict][:body],:remarks=>params[:verdict][:remarks],:user_id=>current_user.id)
      unless (params[:message_ids].blank?) or (params[:verdict][:body]).blank?
        if @verdict.save
          @discipline_complaint.update_attributes(:updated_at=>Date.today)
          (params[:message_ids]).each do |f|
            @verdict.discipline_student_actions.create(:discipline_participation_id=>f)
          end
          render(:update) do |page|
            page.replace_html "take-action",:partial=>"decision",:object=>@verdict
          end
        else
          render(:update) do |page|
            page.replace_html "error",:partial=>"error"
          end
        end
      else
        if params[:verdict][:remarks].blank?
          @verdict.errors.add_to_base("#{t('verdict_cant_blank')}")
        end
        if params[:verdict][:body].blank?
          @verdict.errors.add_to_base("#{t('comments_cant_be_blank')}")
        end
        if params[:message_ids].blank?
          @verdict.errors.add_to_base("#{t('select_atleast_one_accused')}")
        end
        render(:update) do |page|
          page.replace_html "error",:partial=>"error"
        end
      end
    end
  end

  def decision_remove
    @discipline_action=DisciplineAction.find(params[:act_id])
    @discipline_complaint=@discipline_action.discipline_complaint
    @convicted=@discipline_complaint.discipline_accusations
    @discipline_action.destroy
    render(:update) do |page|
      page.replace_html "act#{params[:act_id]}",:text=>""
    end
  end

  def decision_close
    if @discipline_complaint.discipline_actions.blank?
      flash[:notice]="#{t('flash4')}"
      redirect_to:controller=>"discipline_complaints", :action=>"decision"
    else
      @discipline_complaint.update_attributes(:action_taken=>true)
      participants_recipients=[]
      @discipline_complaint.discipline_participations.each do |participation|
        participation.update_attributes(:action_taken=>true)
        unless current_user.id==participation.user_id
          participants_recipients.push participation.user_id
        end
      end
      subject = t('complaint')
      body ="#{t('action_taken_on_complaint')} <b>#{@discipline_complaint.subject}</b>"
      links = {:target=>'view_complaint',:target_param=>'discipline_complaint_id',:target_value=>@discipline_complaint.id}
      inform(participants_recipients,body,'Discipline',links)
#      Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => current_user.id,
#          :recipient_ids => participants_recipients,
#          :subject=>subject,
#          :body=>body ))
      @discipline_complaint.update_attributes(:updated_at=>Date.today)
      flash[:notice]="#{t('flash5')}"
      redirect_to:controller=>"discipline_complaints", :action=>"index"
    end
  end
  private
  def complaint_present
    @discipline_complaint=DisciplineComplaint.find(params[:id])
  end
end
