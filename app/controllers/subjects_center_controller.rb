class SubjectsCenterController < ApplicationController
  before_filter :login_required
  before_filter :old_school_check, :only => [:subject_link_form, :link_batches, :connect_subjects]
  before_filter :find_course, :only => [:new_component, :create_component, :update_component, :edit_component]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  before_filter :fetch_skill_sets, :only => [:new_component, :create_component, :update_component, :edit_component]
  
  def new_component
    @component = params[:type].camelize.constantize.new(component_params)
    render_component_form
  end
  
  def create_component
    @component = params[:type].camelize.constantize.new(params[params[:type].to_sym])
    if @component.save
      flash[:notice] = "#{t('created_component_'+params[:type])}"
      redirect_page_to(:course_subjects, :course_id,  params[:course_id])
    else
      render_component_form
    end
  end

  def update_component
    @component = params[:type].camelize.constantize.find(params[:id])
    if @component.update_attributes(params[params[:type].to_sym])
      flash[:notice] = "#{t('updated_component_'+params[:type])}"
      redirect_page_to :course_subjects, :course_id, params[:course_id]
    else
      render_component_form
    end
  end
  
  def edit_component
    @component = params[:type].camelize.constantize.find(params[:id])
    render_component_form
  end
  
  def delete_component
    @component = params[:type].camelize.constantize.find(params[:id])
    @component.check_and_destroy
    flash[:notice] = "#{t('deleted_component_'+params[:type])}"
    redirect_page_to(:course_subjects, :course_id, params[:course_id])
  end
  
  def course_subjects
    @courses = Course.active
    if params[:course_id].present?
      @course = Course.find(params[:course_id], :include => 
          [:course_elective_groups, {:subject_groups => 
              [:course_subjects, {:course_elective_groups => :course_subjects}]
          }, :course_subjects])
      @components = @course.subject_components
    end
  end
  
  def list_subjects
    @course = Course.find(params[:course_id], :include => 
        [:course_elective_groups, {:subject_groups => 
            [:course_subjects, {:course_elective_groups => :course_subjects}]
        }, :course_subjects])
    @components = @course.subject_components
    render :update do |page|
      page.replace_html 'subject_list', :partial => 'subject_list'
      page.replace_html 'import_logs', :partial => 'import_logs_link'
    end
  end
  
  def link_batches
    if params[:course_id].present?
#      @course = Course.find(params[:course_id],:include => 
#          [:batches, {:all_course_subjects => :subjects}]
#      )
      @course = Course.find(params[:course_id],:include => 
          [:batches, {:all_course_subjects => 
              {:subjects => [:batch, :exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]}
          }]
      )
    end
    @courses = Course.active
    @subjects = @course.build_all_course_subjects_with_batches if @course.present?
  end
  
  def link_batches_submission
    if params[:course_id].present?
      @course = Course.find(params[:course_id],:include => 
          [:batches, {:all_course_subjects => 
              {:subjects => [:batch, :exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]}
          }]
      )
    end
    @courses = Course.active
    if params[:course].present? 
      sub_attr = params[:course][:all_course_subjects_attributes]["#{params[:subject_id]}"][:subjects_attributes]
      cs = CourseSubject.find_by_id(params[:subject_id])
      if cs.present? and cs.update_attributes(:subjects_attributes => sub_attr)
        @subjects = @course.build_all_course_subjects_with_batches(params[:subject_id]) if params[:subject_id].present?
        subjects_activated  =  @subjects.first.subjects.active_batch_subjects.select{|p| !p.new_record? and !p.is_deleted }
        subjects_not_activated  =  @subjects.first.subjects.select{|p| p.new_record? }
        text = allocation_status_html(subjects_activated,subjects_not_activated)
        count = subjects_activated.group_by(&:batch_id).count
        render :update do |page|
          page.replace_html "subject-status-#{params[:subject_id]}", :text=>"#{t('successfully_updated')}"
          page.replace_html "subject-allocation-status-#{params[:subject_id]}", :text => text
          page.replace_html "subject-allocation-count-#{params[:subject_id]}", :text => count
          page.replace_html "subject_link_sub_form_#{params[:subject_id]}", :partial => 'subject_link_sub_form' 
        end
      else
        if cs.present? and cs.errors.present?
          render :update do |page|
            page.replace_html "subject-status-#{params[:subject_id]}", :text=>"#{t('linking_failed')}"
          end
        end 
      end
    else
      render :update do |page|
        page.replace_html "subject-status-#{params[:subject_id]}", :text=>"#{t('successfully_assigned')}"
      end
    end
  end
  
  def subject_link_form
    if params[:course_id].present?
      @course = Course.find(params[:course_id],:include => 
          [:batches, {:all_course_subjects => 
              {:subjects => [:batch, :exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]}
          }]
      )
      @subjects = @course.build_all_course_subjects_with_batches
    end
    render :update do |page|
      page.replace_html 'assign_batch', :partial => 'assign_batch_link' if (@course.present? and @old_school)
      page.replace_html 'assign_batch', :text => '' unless @course.present?
      page.replace_html 'subject_list', :partial => 'subject_link_form'
    end
  end
  
  def subject_link_sub_form
    if params['course_id'].present?
      @course = Course.find(params[:course_id])
#      @course = Course.find(params[:course_id],:include => 
#          [:batches, {:all_course_subjects => :subjects}]
#      )
      @subjects = @course.build_all_course_subjects_with_batches(params['course_subject_id'])
    end
    render :update do |page|
      page.replace_html "subject_link_sub_form_#{params['course_subject_id']}", :partial => 'subject_link_sub_form' 
    end
  end
  
  def allocation_status_html(subjects_activated,subjects_not_activated)
    if subjects_not_activated.present? and !subjects_activated.present? 
      text =  "<span class='not_allocated'>" + "#{t('not_allocated')}" + "</span>"
    elsif subjects_not_activated.present? and subjects_activated.present?
      text =  "<span class='partial'>"+"#{t('partially_allocated')}"+"</span>"
    elsif !subjects_not_activated.present? and subjects_activated.present?
      text =  "<span class='full'>"+"#{t('completely_allocated')}"+"</span>"
    else  
      text =  "<span class='not_eligible'>"+"#{ t('not_eligible')}"+"</span>"
    end
    text
  end
  
  def reorder_components
    @subjects = CourseSubject.configure_priorities(params[:course_subjects][:subject])
    @subjects = SubjectGroup.configure_priorities(params[:course_subjects][:subject_group])
    @subjects = CourseElectiveGroup.configure_priorities(params[:course_subjects][:e_group])
    
    flash[:notice] = "#{t('subject_order_updated')}"
    redirect_page_to(:course_subjects, :course_id, params[:course_id])
  end
  
  def connect_subjects
    unless @old_school
      flash[:notice] = "#{t('not_permitted')}"
      redirect_to :controller => "user", :action => "dashboard"  and return 
    end
    @course = Course.find(params[:course_id], :include => [:batches, :all_course_subjects])
    @course_subjects = @course.all_course_subjects
  end
  
  def list_connectable_subjects
    fetch_connect_form_data
    render :update do |page|
      page.replace_html 'connect_form', :partial => "connect_form"
    end
  end
  
  def list_connectable_batch_subjects
    @batch = Batch.find(params[:batch_id], :include => [{:subjects => [:exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]}, {:course => :all_course_subjects}])
    @course_subject = CourseSubject.find params[:course_subject_id]
    @remaining_subjects = @batch.applicable_unlinked_subjects(@course_subject)
    render :update do |page|
      page.replace_html 'connectable_batch_subjects', :partial => "connectable_batch_subjects"
    end
  end
  
  def unlink_subject
    subject = Subject.find params[:subject_id]
    subject.update_attributes(:course_subject_id => nil)
    fetch_connect_form_data
    render :update do |page|
      page.replace_html 'error', :text=>"<p class='flash-msg'>#{t('subject_has_depenencies')}:#{subject.errors.full_messages.join(',')}</p>" if subject.errors.full_messages.present?
      page.replace_html 'connect_form', :partial => "connect_form"
    end
  end
  
  def link_subjects
    @subject = Subject.find params[:subject_id]
    subject = @subject.link_to_course_subject(params[:course_subject_id])
    fetch_connect_form_data
    render :update do |page|
      page.replace_html 'error', :text=>"<p class='flash-msg'>#{t('subject_has_depenencies')}:#{subject.errors.full_messages.join(',')}</p>" if subject.errors.full_messages.present?
      page.replace_html 'connect_form', :partial => "connect_form"
    end
  end
  
  def import_subjects
    if request.post?
      @course = Course.find params[:course_id]
      import = @course.subject_imports.new(:parameters => params[:import_subjects])
      if import.save
        flash[:notice] = t('subject_import_in_queue', :log_url => url_for(:controller => "subjects_center", :action => "import_logs", :course_id => @course.id))
      else
        flash[:notice] = "#{t('import_cant_start')}: #{import.errors.full_messages.join(', ')}"
      end
      redirect_page_to(:course_subjects, :course_id, params[:course_id])
    else
      @course_id = params[:course_id]
      @courses = Course.active.all(:joins => :all_course_subjects,:conditions =>['courses.id <> ?', params[:course_id]],
        :group => 'courses.id')
    end
  end
  
  def list_import_subjects
    @course = Course.find(params[:import_from], :include => 
          [:course_elective_groups, {:subject_groups => 
              [:course_subjects, {:course_elective_groups => :course_subjects}]
          }, :course_subjects])
    @components = @course.subject_components
    @imported_components = Course.find(params[:import_to]).imported_components(params[:import_from])
    @import_to = params[:import_to]
    render :update do |page|
      page.replace_html 'import_subject_list', :partial => "import_subject_list"
    end
  end
  
  def import_logs
    @course = Course.find(params[:course_id], :include => :subject_imports)
    @imported_courses = Course.find_all_by_id @course.subject_imports.collect(&:import_from)
  end
  
  private
  
  def render_component_form
    head = component_form_head
    render :update do |page|
      page << "document.body.scrollTop = document.documentElement.scrollTop = 0;"
      page << "build_modal_box({'title' : '#{head}'})" unless params[@component.class.name.underscore.to_sym].present?
      page.replace_html 'popup_content', :partial => "#{@component.class.name.underscore}_form", :locals => {:head => head}
    end
  end
  
  def fetch_connect_form_data
    @batch = Batch.find(params[:batch_id], :include => [{:subjects => [:exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]}, {:course => :all_course_subjects}])
    @subjects_relation = @batch.course_subject_relation
    @remaining_subjects = @batch.unlinked_subjects
    @normal_course_subjects = @batch.course.all_normal_course_subjects
    @elective_course_subjects = @batch.course.all_elective_course_subjects
  end
  
  def component_form_head
    case @component.class.name.underscore
    when 'subject_group'
      @component.new_record? ? t('create_subject_group') : t('update_subject_group') 
    when 'course_elective_group'
      @component.new_record? ? t('create_course_elective_group') : t('update_course_elective_group') 
    when 'course_subject'
      @component.new_record? ? t('create_subject') : t('update_subject') 
    end
  end
  
  def component_params
    if params[:type] == 'subject_group'
      {:course_id => params[:parent_id]}
    else
      {
        :parent_id => params[:parent_id],
        :parent_type => params[:parent_type],
      }
    end
  end
  
  def fetch_skill_sets
    @skill_sets = SubjectSkillSet.all(:joins => :subject_skills, :group => 'subject_skill_sets.id') if params[:type] == 'course_subject'
  end
  
  def redirect_page_to(action, param_name, param_value)
    render :update do |page|
      page.redirect_to :action => action.to_s, param_name => param_value
    end
  end
  
  def find_course
    @course = Course.find params[:course_id]
  end
  
  def old_school_check
    @old_school = Configuration.get_config_value('EnabledConnectSubject')
  end
  
end
