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

class AssessmentScoresController < ApplicationController
  before_filter :login_required
  before_filter :has_required_params
  filter_access_to :all,:except=>[:observation_groups,:observation_scores,:fa_scores]
  filter_access_to [:observation_groups,:observation_scores], :attribute_check=>true, :load_method => lambda { Batch.find(params[:batch_id]) }
  filter_access_to [:get_fa_groups], :attribute_check=>true, :load_method => lambda { Subject.find(params[:subject_id]) }
  filter_access_to [:fa_scores], :attribute_check=>true, :load_method => lambda { (params[:subject_id].present? ? (Subject.find(params[:subject_id])) : (ExamGroup.find(params[:exam_group_id])))}
  check_request_fingerprint :scores_form
    
  def fa_scores
    @exam_group=ExamGroup.find(params[:exam_group_id])
    @batch=@exam_group.batch
    @fa_groups = []
    @cce_exam_category = @exam_group.cce_exam_category
    if params[:subject_id].present?
      @subject = Subject.find(params[:subject_id],:include=>:exams)
      @exam = @subject.exams.first(:joins=>:exam_group,:conditions=>{:exam_groups=>{:cce_exam_category_id=>@cce_exam_category.id}})
      @fa_groups=@subject.fa_groups.all(:order=>'id asc').select{|fg| fg.cce_exam_category_id == @cce_exam_category.id}.sort_by{|e| e.name.split(' ').last }
    end
    
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      @subjects=@batch.subjects.active
    elsif @current_user.is_a_subject_teacher
      @subjects=@current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>@batch.id,:no_exams=>false}).uniq
    else
      @subjects=[]
    end
  end
  
  def get_fa_groups
    unless params[:subject_id] == "" 
      @subject=Subject.find(params[:subject_id])
      @cce_exam_category = CceExamCategory.find(params[:cce_exam_category_id])
      @fa_groups=@subject.fa_groups.all(:order=>'id asc').select{|fg| fg.cce_exam_category_id == @cce_exam_category.id}.sort_by{|e| e.name.split(' ').last }
    end
    render :update do |page|
      page.replace_html 'fa_groups_list' ,:partial=>'fa_groups_list'
    end
  end
  
  def scores_form
    unless params[:subject_id] == "" or params[:cce_exam_category_id] == ""
      unless params[:fa_group_id] == ""
        @subject=Subject.find(params[:subject_id])
        @cce_exam_category=CceExamCategory.find(params[:cce_exam_category_id])
        if ["FA1","FA2","FA3","FA4"].include? params[:fa_group_id]
          @fa_group = @subject.fa_groups.first(:conditions=>["name LIKE ? and cce_exam_category_id= ?","%#{params[:fa_group_id]}",@cce_exam_category.id])
        else
          @fa_group=FaGroup.find(params[:fa_group_id])
        end
        if @fa_group.present?
          @roll_number_enabled = Student.roll_number_config_value == "1" ? true : false
          @fa_criterias=@fa_group.fa_criterias.active.all(:joins=>:descriptive_indicators,:include=>:descriptive_indicators,:group=>'fa_criterias.id') if @fa_group.present?
          @batch=@subject.batch
          if @subject.elective_group_id.nil?
#            if params[:student_order].present? && params[:student_order] == 'roll_number'
#              @students=@batch.is_active ? @batch.students.all(:order=>"LENGTH(roll_number) ASC,roll_number") : @batch.graduated_students.sort{|a,b| a[:first_name]<=>b[:first_name]}
#            else
#              @students=@batch.is_active ? @batch.students.all(:order=>"first_name ASC,last_name ASC") : @batch.graduated_students.sort{|a,b| a[:first_name]<=>b[:first_name]}
#            end
              @students=@batch.is_active ? @batch.students.all(:order=>"#{Student.sort_order}") : @batch.sorted_graduated_students
#            end
          else
#            if params[:student_order].present? && params[:student_order] == 'roll_number'
#              @students=@subject.students.find(:all,:conditions=>{:batch_id=>@batch.id},:order=>"LENGTH(roll_number) ASC,roll_number")
#            else
#              @students=@subject.students.find(:all,:conditions=>{:batch_id=>@batch.id},:order=>"first_name ASC,last_name ASC")
#            end
              @students=@subject.students.all( :joins => "left join batch_students on students.id=batch_students.student_id", :conditions=> ["students.batch_id = ? or batch_students.batch_id = ?", @batch.id, @batch.id], :order=>"#{Student.sort_order}")
          end
          if @students.present?
            if params[:grade].present?
              status = AssessmentScore.save_fa_scores(params[:grade],@batch,@subject,@cce_exam_category)
              if status == 1
                @notice='Error Occured'
              else
                @notice = 'Grades saved successfully'
              end
            end
    
            di=@fa_criterias.collect(&:descriptive_indicator_ids).flatten
            @scores=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
            scores=AssessmentScore.find(:all,:conditions=>{:batch_id=>@batch.id,:descriptive_indicator_id=>di, :subject_id=>@subject.id,:cce_exam_category_id=>@cce_exam_category.id}).group_by(&:student_id)
            scores.each do |k,v|
              @scores[k]=v.group_by{|g| g.descriptive_indicator_id}
            end
    
            render(:update) do |page|
              page.replace_html   'fa_sheet', :partial=>"fa_sheet"
              page.replace_html   'flash-box', :text=>"<p class='flash-msg'>#{@notice}</p>" unless @notice.nil?
            end
          else
            render(:update) do |page|
              page.replace_html   'fa_sheet', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'>No students present in this batch</p></div>"
            end
          end
        else
          render(:update) do |page|
            page.replace_html   'fa_sheet', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'>#{params[:fa_group_id]} not assigned for this subject</p></div>"
          end
        end
      else
        render(:update) do |page|
          page.replace_html 'fa_sheet', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> Select an FA group</p></div>"
        end
      end
    else
      render(:update) do |page|
        page.replace_html 'fa_sheet', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> Select a subject</p></div>"
      end
    end
  end
  
  def observation_groups
    @batch=Batch.find(params[:batch_id])
    if @current_user.employee?
      privilege = @current_user.privileges.map{|p| p.name}
      employee= @current_user.employee_record
    end
    @observation_groups=@batch.course.observation_groups.active.all(:order=>'sort_order ASC')
  end

  def observation_scores
    if params[:request_type].present?
      render :js=>"window.location='#{observation_scores_path(:batch_id=>params[:batch_id],:observation_group_id=>params[:observation_group_new_id],:student=>params[:student])}'"
    else
      @roll_number_enabled = Student.roll_number_config_value == "1" ? true : false
      @batch=Batch.find(params[:batch_id])
      @observation_group=ObservationGroup.find(params[:observation_group_id])
      @observation_groups=@batch.course.observation_groups.active.all(:order=>'name ASC')
      @observations=@observation_group.observations.find(:all,:conditions=>{:is_active=>true},:order=>"sort_order ASC")
#      @students=@batch.is_active ? @batch.students.all(:order=>"#{Student.sort_order}") : @batch.graduated_students.sort{|a,b| a[:first_name]<=>b[:first_name]}
      @students=@batch.is_active ? @batch.students.all(:order=>"#{Student.sort_order}") : @batch.sorted_graduated_students
      
      if params[:student].present?
        @student=Student.find(params[:student])
      else
        @student=@students.first
      end
      @grading_levels=@observation_group.cce_grade_set.cce_grades
      di=@observations.collect(&:descriptive_indicator_ids).flatten
      ob_ids = @observations.collect(&:id).flatten
      @scores=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      scores=AssessmentScore.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id,:descriptive_indicator_id=>di}).group_by(&:student_id)
      scores.each do |k,v|
        @scores[k]=v.group_by{|g| g.descriptive_indicator_id}
      end
      @remarks=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc)}
      if @student.present?
        remarks = @student.student_coscholastic_remarks.find(:all, :conditions=>{:observation_id => ob_ids}).group_by(&:student_id) 
        remarks.each do |k,v|
          @remarks[k]=v.group_by{|g| g.observation_id}
        end
      end
      if request.post?
        unless params[:grade].present?
          @student=Student.find(params[:student])
          render(:update) do |page|
            page.replace_html 'student_list', :partial=>'student_list'
            page.replace_html   'observation_sheet', :partial=>"observation_sheet"
          end
        else
          AssessmentScore.transaction do
            params[:grade].each_pair do |indicator,point|
              @student=Student.find(params[:student_id])
              batch = @batch.id
              score = @student.observation_score_for(indicator, batch)
              unless point.blank?
                score.grade_points=point.to_f
                score.batch_id=batch
                unless score.save
                  @err=1
                end
              else
                unless score.destroy
                  @err=1
                end
              end
            end
            @student=Student.find(params[:student_id])
            if params[:remarks].present?
              params[:remarks].each_pair do |observation, remark|
                coscholastic_remark = @student.student_coscholastic_remarks.find_or_initialize_by_observation_id(observation)
                coscholastic_remark.remark = remark
                coscholastic_remark.batch_id = @batch.id
                coscholastic_remark.save
              end
            end
          end
          if @err
            flash[:notice]='Error Occured'
          else
            flash[:notice]='Grades saved successfully'
          end
          render :js=>"window.location='#{observation_scores_path(:batch_id=>@batch.id,:observation_group_id=>@observation_group.id,:student=>@student.id)}'"
        end
      end
    end
  end
  
  def search_batch_students
    query = params[:query]
    @batch = Batch.find params[:batch_id]
    @observation_group = ObservationGroup.find(params[:observation_group_id])
    @roll_number_enabled = Student.roll_number_config_value == "1" ? true : false
    if query.length>= 1
      @students = @batch.students.find(:all,
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR admission_no LIKE ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ) ",
          "%#{query}%", "%#{query}%", "%#{query}%",
          "%#{query}", "%#{query}"],
        :order => "#{Student.check_and_sort}") unless query == ''
    else
      @students = @batch.students.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "first_name asc") unless query == ''
      @students = @batch.is_active ? @batch.students.all(:order=>"#{Student.check_and_sort}") : @batch.sorted_graduated_students if query.blank?
    end
    render :layout => false
  end
  
  def get_grade
    score = params[:average]
    ob_group= ObservationGroup.find(params[:observation_group_id])
    grade = ob_group.cce_grade_set.grade_string_for(score)
#    grades=ob_group.cce_grade_set.cce_grades
#    grade = grades.to_a.find{|g| g.grade_point <= score.to_f.round(2).round}.try(:name) || ""
    render :text=> grade
  end
  
  def has_required_params
    case params[:action]
    when 'get_fa_groups'
      handle_params_failure(params[:subject_id],[:@fa_groups],[['fa_groups_list',{:partial=>'fa_groups_list'}]])
    end
  end

end
