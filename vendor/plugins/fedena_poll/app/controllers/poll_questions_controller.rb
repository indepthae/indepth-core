class PollQuestionsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except=>:show
  filter_access_to :show , :attribute_check => true
  filter_access_to :voting,:attribute_check => true,:load_method => lambda {PollQuestion.find(params[:id])}
  before_filter :find_poll, :only => [:show, :edit, :update, :voting]
  before_filter :poll_is_active, :only => [:voting]

  def index
    @user = @current_user
    if @user.admin
      @poll_questions_active =  PollQuestion.find(:all, :conditions => 'is_active = 1',:order=>"id desc")
      @poll_questions_inactive =  PollQuestion.find(:all, :conditions => 'is_active = 0',:order=>"id desc")
    elsif
      @current_user.student
      @poll_questions_active = @current_user.student_record.poll_question.find(:all,:conditions=>{:is_active=>true},:order=>"id desc")
      @poll_questions_inactive = @current_user.student_record.poll_question.find(:all,:conditions=>{:is_active=>false},:order=>"id desc")

    elsif
      @current_user.employee
      if @current_user.privileges.map{|p| p.name}.include?('PollControl')
        @poll_questions_active = PollQuestion.find(:all, :conditions => 'is_active = 1',:order=>"id desc")
        @poll_questions_inactive = PollQuestion.find(:all, :conditions => 'is_active = 0',:order=>"id desc")
      else
        @poll_questions_active = @current_user.employee_record.poll_question.find(:all,:conditions=>{:is_active=>true},:order=>"id desc")
        @poll_questions_inactive = @current_user.employee_record.poll_question.find(:all,:conditions=>{:is_active=>false},:order=>"id desc")
      end
    end
  end

  def new
    @batches = Batch.active.all
    @departments = EmployeeDepartment.active_and_ordered
    @poll_question =  PollQuestion.new
    2.times {@poll_question.poll_options.build }
  end

  def show
    @user = @current_user
    if @poll_question.poll_question_can_be_viewed_by?(@user)
      @poll_votes_count=@poll_question.poll_votes.count(:group => :poll_option_id)
    else
      flash[:notice] = t('flash_poll1')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end

  def edit
    @user = @current_user
    @poll_question = PollQuestion.find(params[:id])
    if @poll_question.is_active and @poll_question.poll_votes.empty?
      if @poll_question.poll_question_can_be_edited_by?(@user)
        @batches_ids =@poll_question.poll_members.find(:all,:conditions=>['member_type=?',"Batch"]).collect(&:member_id)
        @departments_ids =@poll_question.poll_members.find(:all,:conditions=>['member_type=?',"EmployeeDepartment"]).collect(&:member_id)
        @batches = Batch.active.all
        @departments = EmployeeDepartment.active_and_ordered
      else
        flash[:notice] = t('flash_poll2')
        redirect_to :controller => 'user',:action => 'dashboard'
      end
    else
      flash[:notice] = t('flash_poll2')
      redirect_to(@poll_question)
    end
  end
  def create
    flag = 0
    @poll_question =  PollQuestion.new(params[:poll_question])
    @poll_question.poll_creator_id=@current_user.id
    @batch_ids = (params[:batch_ids].present?  ? params[:batch_ids]:[])
    @department_ids = (params[:department_ids].present?  ? params[:department_ids]:[])

    if @poll_question.save
      unless @batch_ids.blank?
        @batch_ids.each do |batch|
          @poll_member=PollMember.new
          pollbatch = Batch.find(batch)
          @poll_member.poll_question_id=@poll_question.id
          @poll_member.member = pollbatch
          if @poll_member.save
          else
            flag = 1
          end
        end
      end
      unless @department_ids.blank?
        @department_ids.each do |department|
          @poll_member=PollMember.new
          polldepartment = EmployeeDepartment.find(department)
          @poll_member.poll_question_id=@poll_question.id
          @poll_member.member = polldepartment
          if @poll_member.save
          else
            flag = 1
          end
        end
      end
    else
      flag = 1
    end
    if flag == 0
      flash[:notice] = "Poll created"
      redirect_to :action => 'index'
    else
      @flag=1
      @batches = Batch.active.all
      @departments = EmployeeDepartment.active_and_ordered
      render 'new'
    end
  end


  def update
    flag = 0
    @user = @current_user
    batch_ids = (params[:batch_ids].present?  ? params[:batch_ids]:[])
    department_ids = (params[:department_ids].present?  ? params[:department_ids]:[])
    if @poll_question.poll_question_can_be_edited_by?(@user)
      if @poll_question.update_attributes(params[:poll_question])
        batch_all_ids=PollMember.find(:all,:conditions=>['member_type=? and poll_question_id=?',"Batch",@poll_question]).collect(&:member_id).collect{|i| i.to_s}

        @batch_ids=batch_ids - batch_all_ids unless batch_ids.blank?
        b_ids=batch_all_ids -batch_ids unless batch_all_ids.blank?
        unless b_ids.blank?
          b_ids.each do |id|
            @poll_question.poll_members.find_by_member_type_and_member_id("Batch",id).destroy
          end
        end
        unless @batch_ids.blank?
          @batch_ids.each do |batch|
            @poll_member=PollMember.new
            pollbatch = Batch.find(batch)
            @poll_member.poll_question_id=@poll_question.id
            @poll_member.member = pollbatch
            flag = 1 unless @poll_member.save
          end
        end
        department_all_ids=PollMember.find(:all,:conditions=>['member_type=? and poll_question_id=?',"EmployeeDepartment",@poll_question]).collect(&:member_id).collect{|i| i.to_s}
        @department_ids=department_ids-department_all_ids unless department_ids.blank?
        d_ids=department_all_ids -department_ids unless department_all_ids.blank?
        unless d_ids.blank?
          d_ids.each do |id|
            @poll_question.poll_members.find_by_member_type_and_member_id("EmployeeDepartment",id).destroy
          end
        end
        unless @department_ids.blank?
          @department_ids.each do |department|
            @poll_member=PollMember.new
            polldepartment = EmployeeDepartment.find(department)
            @poll_member.poll_question_id=@poll_question.id
            @poll_member.member = polldepartment
            flag = 1 unless @poll_member.save
          end
        end
      else
        flag =1
      end
      if flag ==0
        flash[:notice] = t('flash_poll4')
        redirect_to(@poll_question)
      else
        @batches_ids = (params[:batch_ids].present?  ? params[:batch_ids].collect{|a| a.to_i}:[])
        @departments_ids = (params[:department_ids].present?  ? params[:department_ids].collect{|a| a.to_i}:[])
        @batches = Batch.active.all
        @departments = EmployeeDepartment.active_and_ordered
        @poll_options=@poll_question.poll_options.each{|dc| dc[:_destroy] = ""}
        render 'edit'
      end
    else
      flash[:notice] = t('flash_poll5')
    end
  end


  def destroy
    @user = @current_user
    @poll_question =  PollQuestion.find(params[:id])
    if @poll_question.poll_question_can_be_deleted_by?(@user)
      @poll_question.destroy
      flash[:notice] = t('flash_poll6')
      redirect_to :action=> 'index'
    else
      flash[:notice] = t('flash_msg7')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end

  def voting
    @user = @current_user
    if request.post?
      if @poll_question.poll_question_can_be_viewed_by?(@user)
        if params[:custom_answer].present?
          @poll_question.poll_votes.build(:custom_answer=>params[:custom_answer], :user_id=>@current_user.id)
        else
          @poll_question.poll_votes.build(:poll_option_id => params[:poll_option],:user_id=>@current_user.id)
        end
        if @poll_question.save
          flash[:notice] = t('flash_poll8')
          redirect_to(:action => "index")
        else
          flash[:warn_notice] = "#{@poll_question.poll_votes.collect{ |pv| pv.errors.full_messages}.flatten.join(' ')}"
        end
      else
        flash[:notice] = t('flash_poll9')
        redirect_to :controller => 'user',:action => 'dashboard'
      end
    end
  end

  def close_poll
    @user = @current_user
    @poll_question = PollQuestion.find(params[:id])
    if @poll_question.poll_question_can_be_edited_by?(@user)
      @poll_question.update_attributes(:is_active => false)
      flash[:notice] = t('flash_poll10')
      redirect_to :action => 'index'
    else
      flash[:notice] = t('flash_poll11')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end

  def open_poll
    @user = @current_user
    @poll_question = PollQuestion.find(params[:id])
    if @poll_question.poll_question_can_be_edited_by?(@user)
      @poll_question.update_attributes(:is_active => true)
      flash[:notice] = t('flash_poll12')
      redirect_to :action => 'index'
    else
      flash[:notice] = t('flash_poll13')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end
  private
  def poll_is_active
    @poll_question=PollQuestion.find(params[:id])
    unless @poll_question.is_active
      flash[:notice]= t('flash_poll14')
      redirect_to (@poll_question)
    end
  end

  def find_poll
    @poll_question=PollQuestion.find_by_id(params[:id])
    if @poll_question.blank?
      flash[:notice]= t('flash_poll15')
      redirect_to (poll_questions_path) and return
    end
  end
end
