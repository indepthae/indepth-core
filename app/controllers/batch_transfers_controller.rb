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

class BatchTransfersController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @batches = Batch.active
  end

  def show
    flash[:notice] = nil
    @batch = Batch.find params[:id], :include => [:students],:order => "students.first_name ASC"
    @batches = Batch.active - @batch.to_a
    @student= Student.find(params[:student_id]) if params[:student_id].present?
    defaulter_students = @batch.students.students_with_pending_fees
    if defaulter_students.present?
      flash[:notice] = "#{t('flash5')}"
    end
  end

  def transfer
    if request.post?
      @batch = Batch.find params[:id], :include => [:students],:order => "students.first_name ASC"
      if params[:transfer][:to].present?
        unless params[:transfer][:students].nil?
          students = Student.find(params[:transfer][:students])
          students.each do |s|
            s.transfer_to_batch(@batch,params[:transfer][:to],params[:transfer][:attendance])
            s.reload
            #            s.update_attribute(:has_paid_fees_for_batch,0)
          end
        end
        batch = @batch
        @stu = Student.find_all_by_batch_id(batch.id)
        if @stu.empty?
          batch.update_attribute :is_active, false
#   =======    Issue fix 8454 ==  Uncheck subsequent 5 lines if the employee subject assoication must be deleted ==========
#          Subject.find_all_by_batch_id(batch.id).each do |sub|
#            sub.employees_subjects.each do |emp_sub|
#              emp_sub.delete
#            end
#          end
        end
        flash[:notice] = "#{t('flash1')}"
        batch = Batch.find params[:transfer][:to]
        if batch.course.enable_student_elective_selection
          unless batch.elective_groups.active.empty? #&& batch.subjects.select{|es| es.elective_group_id != nil}.blank?
            batch.elective_groups.active.each do |eg|
              if !eg.end_date.nil? && !eg.subjects.active.empty? && eg.end_date >= Date.today
                end_date = eg.end_date
                recipients_array = []
                students.each do |s|
                  recipients_array << s.user.id << (s.immediate_contact.user.id unless s.immediate_contact.nil? )
                end
              end
              content = "Electives for group #{eg.name} are available.Please select it on or before #{end_date}"
              links = {:target=>'choose_elective',:target_param=>'student_id'}
              inform(recipients_array,content,"Subject",links)
            end
          end
        end
        redirect_to :controller => 'batch_transfers'
      else
        @batches = Batch.active - @batch.to_a
        @batch.errors.add_to_base("#{t('select_a_batch_to_continue')}")
        render :template=> "batch_transfers/show"
      end
    else
      redirect_to :action=>"show", :id=> params[:id]
    end
  end

  def graduation
    @batch = Batch.find params[:id], :include => [:students], :order => "students.first_name ASC"
    defaulter_students = @batch.students.collect{|student| student.finance_fees}.flatten.collect{|s| s.is_paid}
    if defaulter_students.include? false
      flash[:warning] = "#{t('flash5')}"
    end
    params[:ids]
    unless params[:ids].nil?
      @ids = params[:ids]
      @id_lists = @ids.map { |st_id| ArchivedStudent.first(:conditions => ["admission_no LIKE BINARY(?)",st_id]) }
    end
    if request.post?
      student_id_list = params[:graduate][:students]
      @student_list = student_id_list.map { |st_id| Student.find(st_id) }
      @admission_list = []
      @student_list.each do |s|
        @admission_list.push s.admission_no
      end
      @student_list.each { |s| s.archive_student(params[:graduate][:status_description],params[:leaving_date]) }
      @stu = Student.find_all_by_batch_id(@batch.id)
      if @stu.empty?
        @batch.update_attribute :is_active, false
        @batch.employees_subjects.destroy_all
        #          flash[:notice]="Graduated selected students successfully."
        #          redirect_to :controller=>'batch_transfers' and return
      end
      flash[:notice]= "#{t('flash2')}"
      redirect_to :action=>"graduation", :id=>params[:id], :ids => @admission_list
    end
  end

  def subject_transfer
    @batch = Batch.find(params[:id])
    @elective_groups = @batch.elective_groups.all(:conditions => {:is_deleted => false})
    @normal_subjects = @batch.normal_batch_subject
    @elective_subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"])
  end

  def get_previous_batch_subjects
    @batch = Batch.find(params[:id])
    course_id = @batch.course_id
    @previous_batch = Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id }'",:joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
    unless @previous_batch.blank?
      @previous_batch_normal_subject = @previous_batch.normal_batch_subject
      @elective_groups = @previous_batch.elective_groups.all(:conditions => {:is_deleted => false})
      @previous_batch_electives = Subject.find_all_by_batch_id(@previous_batch.id,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"])
      render(:update) do |page|
        page.replace_html 'previous-batch-subjects', :partial=>"previous_batch_subjects"
      end
    else
      render(:update) do |page|
        page.replace_html 'msg', :text=>"<p class='flash-msg'>#{t('batch_transfers.flash4')}</p>"
      end
    end
  end

  def update_batch
    if params[:course_name].present?
      @batches = Batch.find_all_by_course_id(params[:course_name], :conditions => { :is_deleted => false, :is_active => true })
      render(:update) do |page|
        page.replace_html 'update_batch', :partial=>'list_courses'
      end
    else
      render(:update) do |page|
        page.replace_html 'update_batch', :text=>''
      end
    end
  end

  def assign_previous_batch_subject
    subject = Subject.find(params[:id])
    batch = Batch.find(params[:id2])
    sub_exists = Subject.find_by_batch_id_and_name(batch.id,subject.name, :conditions => { :is_deleted => false},:include=>:elective_group)
    if sub_exists.nil?
      if subject.elective_group_id == nil
        sub = Subject.new(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
          :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>subject.elective_group_id,:is_deleted=>false,:is_asl=>subject.is_asl,:asl_mark=>subject.asl_mark,:is_sixth_subject=>subject.is_sixth_subject)
        unless sub.save
          render(:update) do |page|
            page.replace_html "prev-subject-name-#{subject.id}", :text=>""
            errors_msg=[]
            errors_msg += sub.errors.full_messages
            page.replace_html "errors", :text=>"<div class=\"errorExplanation\" ><p>#{subject.name} #{t('cannot_be_imported_to_the_batch')} #{batch.name} #{t('since')} #{errors_msg.join(' and ')}</p></div>"
          end
        else
          render(:update) do |page|
            page.replace_html "prev-subject-name-#{subject.id}", :text=>""
            page.replace_html "errors", :text=>"#{subject.name}  #{t('has_been_added_to_batch')}:#{batch.name}"
          end
        end
      else
        elect_group_exists = ElectiveGroup.find_by_name_and_batch_id(ElectiveGroup.find(subject.elective_group_id).name,batch.id,:conditions => {:is_deleted => false})
        if elect_group_exists.nil?
          elect_group = ElectiveGroup.new(:name=>subject.elective_group.name,
            :batch_id=>batch.id,:is_deleted=>false,:is_sixth_subject=>subject.elective_group.is_sixth_subject)
          unless elect_group.save
            errors_msg=[]
            errors_msg += elect_group.errors.full_messages
            @err +=   "<li>#{elect_group.name} #{t('cannot_be_imported_to_the_batch')} #{batch.name} #{t('since')} #{errors_msg.join(' and ')}" + "</li>"
          else
            Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
              :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>elect_group.id,:is_deleted=>false)
          end
        else
          Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
            :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>elect_group_exists.id,:is_deleted=>false)
        end
        render(:update) do |page|
          page.replace_html "prev-subject-name-#{subject.id}", :text=>""
          page.replace_html "errors", :text=>"#{subject.name}  #{t('has_been_added_to_batch')}:#{batch.name}"
        end
      end
    else
      render(:update) do |page|
        page.replace_html "prev-subject-name-#{subject.id}", :text=>""
        page.replace_html "errors", :text=>"<div class=\"errorExplanation\" ><p>#{batch.name} #{t('already_has_subject')} #{subject.name}</p></div>"
      end
    end
  end

  def assign_all_previous_batch_subjects
    msg = ""
    @err = ""
    batch = Batch.find(params[:id])
    course = batch.course
    all_batches = course.batches(:order=>'id asc')
    all_batches.reject! {|b| b.is_deleted?}
    all_batches.reject! {|b| b.subjects.empty?}
    #    @previous_batch = all_batches[all_batches.size-2]
    @previous_batch=Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course.id }'",:joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
    subjects = Subject.find_all_by_batch_id(@previous_batch.id,:conditions=>'is_deleted=false')
    subjects.each do |subject|
      sub_exists = Subject.find_by_batch_id_and_name(batch.id,subject.name, :conditions => { :is_deleted => false})
      if sub_exists.nil?
        if subject.elective_group_id.nil?
          sub = Subject.new(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
            :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>subject.elective_group_id,:is_deleted=>false,:is_asl=>subject.is_asl,:asl_mark=>subject.asl_mark,:is_sixth_subject=>subject.is_sixth_subject)
          unless sub.save
            errors_msg=[]
            errors_msg += sub.errors.full_messages
            @err +=   "<li>#{subject.name} #{t('cannot_be_imported_to_the_batch')} #{batch.name} #{t('since')} #{errors_msg.join(' and ')}" + "</li>"
          else
            msg += "<li> #{t('the_subject')} #{subject.name}  #{t('has_been_added_to_batch')} #{batch.name}</li>"
          end
        else
          elect_group_exists = ElectiveGroup.find_by_name_and_batch_id(ElectiveGroup.find(subject.elective_group_id).name,batch.id,:conditions => {:is_deleted => false})
          if elect_group_exists.nil?
            elect_group = ElectiveGroup.new(:name=>subject.elective_group.name,
              :batch_id=>batch.id,:is_deleted=>false,:is_sixth_subject=>subject.elective_group.is_sixth_subject)
            unless elect_group.save
              errors_msg=[]
              errors_msg += elect_group.errors.full_messages
              @err +=   "<li>#{elect_group.name} #{t('cannot_be_imported_to_the_batch')} #{batch.name} #{t('since')} #{errors_msg.join(' and ')}" + "</li>"
            else
              Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
                :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>elect_group.id,:is_deleted=>false)
            end
          else
            Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>batch.id,:no_exams=>subject.no_exams,
              :max_weekly_classes=>subject.max_weekly_classes,:credit_hours=>subject.credit_hours,:elective_group_id=>elect_group_exists.id,:is_deleted=>false)
            msg += "<li> #{t('the_subject')} #{subject.name}  #{t('has_been_added_to_batch')} #{batch.name}</li>"
          end

        end
      else
        @err +=   "<li>#{t('batch')} #{batch.name} #{t('already_has_subject')} #{subject.name}" + "</li>"
      end
    end
    @batch = batch
    course = batch.course
    all_batches = course.batches
    #    @previous_batch = all_batches[all_batches.size-2]
    Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course.id }'",:joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
    @previous_batch_normal_subject = @previous_batch.normal_batch_subject
    @elective_groups = @previous_batch.elective_groups
    @previous_batch_electives = Subject.find_all_by_batch_id(@previous_batch.id,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"])
    render(:update) do |page|
      unless msg.empty?
        page.replace_html 'previous-batch-subjects', :text=>"<p>#{t('subjects_assigned')}</p> "
        page.replace_html "msg", :text=>"<div class=\"flash-msg\"><ul>" +msg +"</ul></p>"
      end
      unless @err.empty?
        page.replace_html "errors", :text=>"<div class=\"errorExplanation\" ><p>#{t('following_errors_found')} :</p><ul>" +@err + "</ul></div>"
      end
    end

  end



  def new_subject
    @subject = Subject.new
    @batch = Batch.find params[:id] if request.xhr? and params[:id]
    @elective_group = ElectiveGroup.find params[:id2] unless params[:id2].nil?
    respond_to do |format|
      format.js { render :action => 'new_subject' }
    end
  end

  def create_subject
    @subject = Subject.new(params[:subject])
    @batch = @subject.batch
    if @subject.save
      @subjects = @subject.batch.normal_batch_subject
      @normal_subjects = @subjects
      @elective_groups = @batch.elective_groups.all(:conditions => {:is_deleted => false})
      @elective_subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"])
    else
      @error = true
    end
  end
  def attendance_transfer
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @batch = Batch.find params[:batch], :include => [:students],:order => "students.first_name ASC"
    @batches = params[:batches]
    @student= Student.find(params[:student_id]) if params[:student_id].present?
    defaulter_students = @batch.students.students_with_pending_fees
    render :update do |page|   
      page.replace_html 'show_students', :partial => 'attendance_transfer'
    end
  end
end
